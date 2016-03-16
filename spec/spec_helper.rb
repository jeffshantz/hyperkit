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

def unauthenticated_client
  cli = Hyperkit::Client.new
  cli.client_cert = cli.client_key = nil
  cli
end

def test_certificate
<<-EOF
-----BEGIN CERTIFICATE-----
MIIEDTCCAvWgAwIBAgIJAP2x5XIwszwpMA0GCSqGSIb3DQEBCwUAMIGcMQswCQYD
VQQGEwJDQTEQMA4GA1UECAwHT250YXJpbzEPMA0GA1UEBwwGTG9uZG9uMRwwGgYD
VQQKDBNFeGFtcGxlIENvcnBvcmF0aW9uMRUwEwYDVQQLDAxFeGFtcGxlIFVuaXQx
FDASBgNVBAMMC2V4YW1wbGUuY29tMR8wHQYJKoZIhvcNAQkBFhBqZWZmQGV4YW1w
bGUuY29tMB4XDTE2MDMxNjAyMzA0NFoXDTI2MDMxNDAyMzA0NFowgZwxCzAJBgNV
BAYTAkNBMRAwDgYDVQQIDAdPbnRhcmlvMQ8wDQYDVQQHDAZMb25kb24xHDAaBgNV
BAoME0V4YW1wbGUgQ29ycG9yYXRpb24xFTATBgNVBAsMDEV4YW1wbGUgVW5pdDEU
MBIGA1UEAwwLZXhhbXBsZS5jb20xHzAdBgkqhkiG9w0BCQEWEGplZmZAZXhhbXBs
ZS5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDdaPN+xiLWDA8j
24zMyx+2YBg+8emf/WSC7pD+8hm4TzPtTUzfJssGgrcZARqUnzvWZ5XinhgBTAg3
JP3qB8MMfI+UVgbHMododafVAglOOrosi10hzNMsSMDws5k1jNj2iZd0tLGB0w4i
E9oGCnpzKV9oQZqg148UQhgrZSfY5vSOQvAES7PU0/Dyox38+6qpqkHwcgGFYJVL
mq6Y4lHoUZmR8cZNYnnr5tLEvXluhDXahlH9yLJ43nDqa6HqwgJHa8Zbd3u5McEF
tnKA7TVN2B839pAOvbnYww5BGFVVkrDUm0f+169DPsh1qbRAeOofSKUTlj8rw/Z+
sEUKqqj5AgMBAAGjUDBOMB0GA1UdDgQWBBSMmA1R+/zdCiiUXyNxWOGbGDT1BTAf
BgNVHSMEGDAWgBSMmA1R+/zdCiiUXyNxWOGbGDT1BTAMBgNVHRMEBTADAQH/MA0G
CSqGSIb3DQEBCwUAA4IBAQBN9rcdFFkK0cvb4JZY7PcHG6L9KfKvNSuEoJzSuOpi
pAsxlqnlVz1KaiPO1GzN2ikL/Ab5oKnknTXPIPDKlhQYDoAUGUQm6s2oijz5MEO/
C3QmbHJdfPiVXY+fuE1wuJLGIB6c+cvozfeEICoLLxXgzizgnD+wGd5M2pDDiQDt
mJbpsG2m97ZkCsH09xpDk01u0EzxoA2oA3n7SHNO/VJXJnOdMtC5qjYo9xZYjU/s
zX6g65tuZyzJg14j9ZtT4EDwMotewuB/BzQ35oYdjUp8VP9I7AZxilNn+HAdwYYN
fkygJ2GGlOc7XAQOrqRlCSQJQKlDK0ZVHhF29RVuibeN
-----END CERTIFICATE-----
EOF

end

def test_certificate_fingerprint
  "05bae8963b233406f67a584dac0cbc6be588d5afa7ccaa676f7cbe55bf98da99"
end

