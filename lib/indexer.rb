# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'logger'
require 'optparse'
require 'pathname'
require 'parallel'
require 'ruby-progressbar'

# A utility class for walking the filesystem looking for WARCs to index. This is
# not meant for everyday usage, but for bootstrapping swap.stanford.edu in
# the event that the CDXJ files need to be created or recreated.
class Indexer
  def initialize(warcs_dir:, indexes_dir:, processes: 1, force_reindex: false)
    @warcs_dir = Pathname.new(warcs_dir)
    @indexes_dir = Pathname.new(indexes_dir)
    raise "missing warcs_dir #{@warcs_dir}" unless @warcs_dir.directory?
    raise "missing indexes_dir #{@index_dir}" unless @indexes_dir.directory?

    @working_dir = @indexes_dir + 'working'
    @working_dir.mkdir unless @working_dir.directory?

    @processes = processes
    @force_reindex = force_reindex
    @log = Logger.new('index.log')
  end

  def run
    @log.info('starting run')
    index_warcs
    merge_indexes
    @log.info('finished')
  end

  def index_warcs
    puts "Finding WARC files in #{@warcs_dir}, which could take a while..."
    warcs = find_warc_files
    puts "Found #{warcs.length} WARC files that need indexing"

    @log.info("Indexing #{warcs.length} WARC files")
    Parallel.map(warcs, in_processes: @processes, progress: 'Indexing') do |warc_file|
      write_cdxj(warc_file)
    end
  end

  def merge_indexes
    cdxj_files = find_cdxj_files
    index_path = Pathname.new(@indexes_dir) + 'index.cdxj'

    # combine all the cdxj indexes into a tmp file
    tmp_path = index_path.sub_ext('.tmp')
    cat(cdxj_files, tmp_path)

    # sort the tmp file into place
    #
    # TMPDIR needs to be set to a partition with lots of space
    #
    # LC_ALL=C is needed to ensure that a byte sort is used
    # See https://specs.webrecorder.net/cdxj/0.1.0/#sorting
    puts('Sorting, this could take a while...')
    @log.info("sorting #{tmp_path} to #{index_path}")
    cmd = "TMPDIR=/web-archiving-stacks/data/tmp/ LC_ALL=C sort #{tmp_path} --output \"#{index_path}\""
    puts('Error while sorting') unless system(cmd)

    tmp_path.unlink
  end

  def cat(source_files, target_file)
    prog = progress_bar('Concatenating', source_files)
    target_file.unlink if target_file.file?
    source_files.each do |source_file|
      @log.info("concatenating #{source_file}")
      cmd = "cat #{source_file} >> \"#{target_file}\""
      puts "Error concatenating #{source_file}" unless system(cmd)
      prog.progress += 1
    end
  end

  def find_warc_files
    # find warc and arc files whether or not they are compressed
    warcs = Pathname.new(@warcs_dir).find.filter do |path|
      path.to_s.match('.w?arc(\.gz)?$')
    end
    if @force_reindex
      warcs
    else
      warcs.filter do |warc|
        cdxj = cdxj_path(warc)
        # return true if the cdxj file isn't there or it's there but it's empty
        !cdxj.file? || cdxj.empty?
      end
    end
  end

  def find_cdxj_files
    Pathname.new(@working_dir).find.filter { |path| path.fnmatch('*.cdxj') }
  end

  def write_cdxj(warc_file)
    cdxj_path = cdxj_path(warc_file)
    cdxj_path.parent.mkpath unless cdxj_path.parent.directory?

    cmd = ['cdxj-indexer', '--post-append', '--output', cdxj_path.to_s, warc_file.to_s]
    @log.info("generating cdxj #{cdxj_path} for #{warc_file}")
    @log.error("cdxj error while parsing #{warc}") unless system(*cmd)

    cdxj_path
  end

  def cdxj_path(warc_file)
    cdx_filename = warc_file.basename.to_s.sub(/w?arc.gz$/, 'cdxj')
    group_dir = Digest::MD5.hexdigest(cdx_filename).slice(0, 2)
    Pathname.new(@working_dir) + group_dir + cdx_filename
  end

  def progress_bar(message, items)
    ProgressBar.create(
      {
        title: message,
        total: items.length,
        format: '%t |%E | %B | %a'
      }
    )
  end
end
