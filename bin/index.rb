#!/usr/bin/env ruby
# frozen_string_literal: true

# This program will walk through WARC files and generate CDXJ files for them.

require 'logger'
require 'optparse'
require 'pathname'
require 'parallel'

WARC_DIR = '/web-archiving-stacks/data/collections'
CDX_DIR = '/data/edsu/indexes'

def main
  opts = {
    max_collections: 100_000_000,
    max_warcs: 100_000_000,
    processes: 1,
    force_reindex: false
  }

  OptionParser.new do |parser|
    parser.on('-c', '--max_collections INT', Integer, 'Maximum collections to index')
    parser.on('-w', '--max_warcs INT', Integer, 'Maximum WARCs in each collection index')
    parser.on('-p', '--processes INT', Integer, 'Number of system processes to use for indexing [1]')
    parser.on('-f', '--force_reindex', 'Force reindexing [False]')
    parser.on('-h', '--help') do
      puts parser
      exit
    end
  end.parse!(into: opts)

  writer = IndexWriter.new(
    max_collections: opts[:max_collections],
    max_warcs: opts[:max_warcs],
    processes: opts[:processes],
    force_reindex: opts[:force_reindex]
  )
  writer.run
end

# A utility class for walking the filesystem looking for WARCs to index.
class IndexWriter
  def initialize(max_collections:, max_warcs:, processes:, force_reindex:)
    @max_collections = max_collections
    @max_warcs = max_warcs
    @processes = processes
    @force_reindex = force_reindex
    @log = Logger.new('index.log')
  end

  def run
    @log.info('starting run')
    bytes = 0
    t0 = Time.new
    results = Parallel.map(jobs, in_processes: @processes, progress: 'Indexing') do |job|
      write_cdx(job)
    end
    bytes += results.sum
    time = Time.new - t0

    puts "#{bytes} bytes"
    puts "#{time} seconds"
    puts "#{bytes / time} bytes/sec" unless time.zero?
  end

  private

  Result = Struct.new(:coll_dir, :warc_file)

  def jobs
    return to_enum(:jobs) unless block_given?

    @log.info('finding jobs')
    collections.take(@max_collections).each do |coll_dir|
      warcs(coll_dir).take(@max_warcs).each do |warc_file|
        yield Result.new(coll_dir, warc_file)
      end
    end
  end

  def collections
    Pathname.new(WARC_DIR).children.select(&:directory?)
  end

  def warcs(coll_dir)
    return to_enum(:warcs, coll_dir) unless block_given?

    Pathname.new(coll_dir).find do |path|
      yield path if path.fnmatch('*arc.gz')
    end
  end

  def write_cdx(job)
    cdx_filename = job.warc_file.basename.to_s.sub(/w?arc.gz$/, 'cdx')
    cdx_path = Pathname.new(CDX_DIR) + job.coll_dir.basename + cdx_filename

    # only create cdx file if it's already there
    if @force_reindex || !cdx_path.file?
      @log.info("generating cdx for #{job.warc_file}")
      cdx_path.parent.mkpath unless cdx_path.parent.directory?
      dir_root = job.coll_dir.to_s
      cmd = ['cdxj-indexer', '--post', '--sort', '--output', cdx_path.to_s, '--dir-root', dir_root, job.warc_file.to_s]
      puts "error processing #{warc_file}" unless system(*cmd)
      job.warc_file.size
    else
      @log.info("cdx file already present #{cdx_path}")
      0
    end
  end
end

main
