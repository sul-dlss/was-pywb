# frozen_string_literal: true

require 'uri'
require 'json'
require 'net/http'
require 'spec_helper'

describe 'Web' do
  it 'loads a page' do
    url = URI('http://localhost:8080/was/20220510010324mp_/https://apod.nasa.gov/apod/astropix.html')
    resp = Net::HTTP.get_response(url)
    expect(resp.body).to match(/Astronomy Picture of the Day/)
  end

  it 'loads a CDX API result' do
    url = URI('http://localhost:8080/was/cdx?url=https://apod.nasa.gov/')
    resp = Net::HTTP.get_response(url)
    lines = resp.body.split("\n")
    expect(lines.length).to eq(3)

    surt, ts, payload_str = lines[0].split(' ', 3)
    expect(surt).to eq('gov,nasa,apod)/')
    expect(ts).to eq('20220510010324')

    payload = JSON.parse(payload_str)
    expect(payload['status']).to eq('301')
    expect(payload['filename']).to eq('apod.warc.gz')
    expect(payload['digest']).to eq('sha1:2NQZDILVRT6JJH3SEZOWX4LRA37Q5IUH')
    expect(payload['length']).to eq('631')
    expect(payload['offset']).to eq('0')
    expect(payload['url']).to eq('https://apod.nasa.gov/')
    expect(payload['mime']).to eq('text/html')
  end

  it 'excludes content' do
    url = URI('http://localhost:8080/was/20220510010324mp_/https://apod.nasa.gov/apod/lib/apsubmit2015.html')
    resp = Net::HTTP.get_response(url)
    expect(resp).to be_instance_of(Net::HTTPNotFound)
  end
end
