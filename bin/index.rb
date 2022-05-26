#!/usr/bin/env ruby
# frozen_string_literal: true

# This program will walk through WARC files and generate CDXJ files for them. It uses
# the --max-warcs and --max-collections arguments to control how many collections and
# warc files per collection to process. It will output timing statistics on how
# long the indexing takes: in mb/sec

require 'optparse'
require 'pathname'

WARC_DIR = '/web-archiving-stacks/data/collections'
CDX_DIR = '/data/edsu/indexes'

def main
  opts = {
    max_collections: 10,
    max_warcs: 10
  }

  OptionParser.new do |parser|
    parser.on('-c', '--max-collections INT', Integer, 'Maximum collections to index [10]') do |i|
      opts[:max_collections] = i
    end
    parser.on('-w', '--max-warcs INT', Integer, 'Maximum WARCs in each collection index [10]') do |i|
      opts[:max_warcs] = i
    end
    parser.on('-h', '--help') do
      puts parser
      exit
    end
  end.parse!

  writer = IndexWriter.new(max_collections: opts[:max_collections], max_warcs: opts[:max_warcs])
  writer.run

  puts "#{writer.bytes / writer.time} bytes/sec"
end

# A utility class for walking the filesystem looking for WARCs to index.
class IndexWriter
  attr_reader :bytes, :time

  def initialize(max_collections:, max_warcs:)
    @max_collections = max_collections
    @max_warcs = max_warcs
    @bytes = 0
    @time = 0
  end

  def run
    seen = {}
    collections.each do |coll_dir|
      seen[coll_dir.to_s] ||= 0
      break if seen.length > @max_collections

      warcs(coll_dir) do |warc_file|
        seen[coll_dir.to_s] += 1
        break if seen[coll_dir.to_s] > @max_warcs

        write_cdx(warc_file: warc_file, coll_name: coll_dir.basename)
      end
    end
  end

  def collections
    Pathname.new(WARC_DIR).children.select(&:directory?)
  end

  def warcs(coll_dir)
    Pathname.new(coll_dir).find do |path|
      yield path if path.fnmatch('*arc.gz')
    end
  end

  def write_cdx(warc_file:, coll_name:)
    @bytes += warc_file.size
    t0 = Time.new
    cdx_filename = warc_file.basename.to_s.sub(/w?arc.gz$/, 'cdx')
    cdx_path = Pathname.new(CDX_DIR) + coll_name + cdx_filename
    cdx_path.parent.mkpath unless cdx_path.parent.directory?

    puts "error processing #{warc_file}" unless system('cdxj-indexer', warc_file.to_s, '--output', cdx_path.to_s)
    @time += Time.new - t0
  end
end

main
