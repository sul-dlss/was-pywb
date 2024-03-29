# frozen_string_literal: true

RSpec.describe Indexer do
  let(:temp_dir) { Dir.mktmpdir }
  let(:warcs_dir) { "#{temp_dir}/warcs" }
  let(:indexes_dir) { "#{temp_dir}/indexes" }

  before do
    FileUtils.mkdir(warcs_dir)
    FileUtils.mkdir(indexes_dir)
    FileUtils.cp('test-data/apod.warc.gz', warcs_dir)
    FileUtils.cp('test-data/stanford.warc.gz', warcs_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  it 'finds warc files' do
    indexer = described_class.new(warcs_dir:, indexes_dir:)
    warc_files = indexer.find_warc_files
    expect(warc_files.length).to eq(2)
    expect(warc_files[0].basename.to_s).to eq('apod.warc.gz')
    expect(warc_files[1].basename.to_s).to eq('stanford.warc.gz')
  end

  it 'indexes warc files' do
    indexer = described_class.new(warcs_dir:, indexes_dir:)
    indexer.run

    index_files = Pathname(indexes_dir).find.filter(&:file?)
    # the intermediary cdxj files are not deleted
    expect(index_files.length).to eq(3)
    expect(index_files[0].basename.to_s).to eq('index.cdxj')

    surts = get_surts(indexes_dir + '/index.cdxj')
    expect(surts.length).to be 711
    expect(surts[0]).to be < surts[1]
  end
end

# parse the cdxj file into a list of SURTs (the keys)
def get_surts(cdxj_file)
  File.new(cdxj_file).map { |line| line.split(' ', 3)[0] }
end
