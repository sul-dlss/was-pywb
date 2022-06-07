#!/usr/bin/env ruby
# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../config/boot")

require 'optparse'

opts = {
  warcs_dir: '/web-archiving-stacks/data/warcs',
  indexes_dir: '/web-archiving-stacks/data/indexes',
  processes: 1,
  force_reindex: false
}

OptionParser.new do |parser|
  parser.on('-w', '--warcs_dir PATH', 'The directory where WARC data lives')
  parser.on('-i', '--indexes_dir PATH', 'The directory where CDX index data lives')
  parser.on('-p', '--processes INT', Integer, 'Number of system processes to use for indexing [1]')
  parser.on('-f', '--force_reindex', 'Force reindexing [False]')
  parser.on('-h', '--help') do
    puts parser
    exit
  end
end.parse!(into: opts)

unless Dir.exist?(opts[:warcs_dir])
  puts 'Use --warcs-dir to point to the directory containing WARC data to index'
  exit
end

unless File.exist?(opts[:indexes_dir])
  puts 'Use --indexes-dir to point to the directory where to write WARC data to'
  exit
end

writer = Indexer.new(
  warcs_dir: opts[:warcs_dir],
  indexes_dir: opts[:indexes_dir],
  processes: opts[:processes],
  force_reindex: opts[:force_reindex]
)

writer.run
