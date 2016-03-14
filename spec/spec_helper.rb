$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
])

SimpleCov.start

require 'json'
require 'hyperkit'
require 'rspec'
require 'webmock/rspec'
require "base64"

WebMock.disable_net_connect!(:allow => 'coveralls.io')

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.before(:each) do
    Hyperkit.reset!
    Hyperkit.api_endpoint = 'https://lxd.example.com:8443'
    Hyperkit.connection_options[:ssl][:verify] = false
  end
end

require 'vcr'

VCR.configure do |c|
  c.configure_rspec_metadata!

  c.default_cassette_options = {
    :serialize_with             => :json,
    :preserve_exact_body_bytes  => true,
    :decode_compressed_response => true,
    :record                     => ENV['TRAVIS'] ? :none : :once
  }
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
end

def stub_delete(url)
  stub_request(:delete, lxd_url(url))
end

def stub_get(url)
  stub_request(:get, lxd_url(url))
end

def stub_head(url)
  stub_request(:head, lxd_url(url))
end

def stub_patch(url)
  stub_request(:patch, lxd_url(url))
end

def stub_post(url)
  stub_request(:post, lxd_url(url))
end

def stub_put(url)
  stub_request(:put, lxd_url(url))
end

def fixture_path
  File.expand_path("../fixtures", __FILE__)
end

def fixture(file)
  File.new(fixture_path + '/' + file)
end

def json_response(file)
  {
    :body => fixture(file),
    :headers => {
      :content_type => 'application/json; charset=utf-8'
    }
  }
end

def lxd_url(url)
  return url if url =~ /^http/

  url = File.join(Hyperkit.api_endpoint, url)
  uri = Addressable::URI.parse(url)
  uri.to_s
end

def use_vcr_placeholder_for(text, replacement)
  VCR.configure do |c|
    c.define_cassette_placeholder(replacement) do
      text
    end
  end
end
