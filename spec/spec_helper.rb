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
require 'digest/sha2'
require 'pry'

WebMock.disable_net_connect!(:allow => 'coveralls.io')

RSpec.configure do |config|

	config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
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
  c.allow_http_connections_when_no_cassette = true
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

def fixture(file, &block)
  File.open(fixture_path + '/' + file, &block)
end

def read_fixture(file)
  fixture(file) do |f|
    return f.read
  end
end

def fixture_fingerprint(file)
  Digest::SHA256.hexdigest(read_fixture(file))
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

def unauthenticated_client
  cli = Hyperkit::Client.new
  cli.client_cert = cli.client_key = nil
  cli
end

def test_cert
  read_fixture("cert-server1.pem")
end

def test_cert_fingerprint
  fixture_fingerprint("cert-server1.pem")
end

def test_cert2
  read_fixture("cert-server2.pem")
end

