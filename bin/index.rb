#!/usr/bin/env ruby
# frozen_string_literal: true

# This program will walk through WARC files and generate CDXJ files for them. It uses
# the --max-warcs and --max-collections arguments to control how many collections and
# warc files per collection to process. It will output timing statistics on how
# long the indexing takes: in mb/sec

require 'optparse'
require 'pathname'
require 'parallel'

WARC_DIR = '/web-archiving-stacks/data/collections'
CDX_DIR = '/data/edsu/indexes'

def main
  opts = {
    max_collections: 100000000,
    max_warcs: 100000000,
    processes: 1
  }

  OptionParser.new do |parser|
    parser.on('-c', '--max_collections INT', Integer, 'Maximum collections to index') 
    parser.on('-w', '--max_warcs INT', Integer, 'Maximum WARCs in each collection index')
    parser.on('-p', '--processes INT', Integer, 'Number of system processes to use for indexing [1]')
    parser.on('-h', '--help') do
      puts parser
      exit
    end
  end.parse!(into: opts)

  writer = IndexWriter.new(
    max_collections: opts[:max_collections],
    max_warcs: opts[:max_warcs],
    processes: opts[:processes]
  )
  writer.run

end

# A utility class for walking the filesystem looking for WARCs to index.
class IndexWriter

  def initialize(max_collections:, max_warcs:, processes:)
    @max_collections = max_collections
    @max_warcs = max_warcs
    @processes = processes
  end

  def run
    bytes = 0
    t0 = Time.new
    results = Parallel.map(jobs, in_processes: @processes, progress: 'Indexing') do |job|
      write_cdx(job)
    end
    bytes += results.sum
    time = Time.new - t0

    puts "#{bytes} bytes"
    puts "#{time} seconds"
    puts "#{bytes / time} bytes/sec" unless time == 0
  end

  private

  Result = Struct.new(:coll_dir, :warc_file)

  def jobs 
    return to_enum(:jobs) unless block_given?
    collections.take(@max_collections).each do |coll_dir|
      puts "coll #{coll_dir}"
      warcs(coll_dir).take(@max_warcs).each do |warc_file|
        puts "yielding #{warc_file}"
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
    cdx_path.parent.mkpath unless cdx_path.parent.directory?
    dir_root = job.coll_dir.to_s

    cmd = ['cdxj-indexer', '--sort', '--output', cdx_path.to_s, '--dir-root', dir_root, job.warc_file.to_s]
    puts "error processing #{warc_file}" unless system(*cmd)
    job.warc_file.size
  end
end

main
