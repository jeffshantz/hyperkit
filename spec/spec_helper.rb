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

begin
  require 'pry'
rescue LoadError
end

WebMock.disable_net_connect!(:allow => 'coveralls.io')

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

Dir["./spec/support/**/*.rb"].sort.each { |f| require f}

RSpec.configure do |config|

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.raise_errors_for_deprecations!
  config.before(:each) do
    Hyperkit.reset!
    Hyperkit.api_endpoint = 'https://192.168.103.101:8443'
    Hyperkit.verify_ssl = false
  end

  config.before(:each, image: true) do |example|
    if ! example.metadata[:skip_create]

      options = example.metadata[:image_options] || {}

      if example.metadata.has_key?(:public)
        options[:public] = example.metadata[:public]
      end

      @fingerprint = create_test_image("busybox/default", options)
    end
  end

  config.after(:each, image: true) do |example|
    unless example.metadata[:skip_delete]
      delete_test_image(@fingerprint)
    end
  end

  config.before(:each, remote_image: true) do |example|

    options = {
      public: true
    }

    if example.metadata.has_key?(:remote_image_options)
      options = options.merge(:remote_image_options)
    end

    create_remote_test_image(options)
  end

  config.after(:each, remote_image: true) do |example|
    delete_remote_test_image
  end


  config.before(:each, container: true) do |example|
    if example.metadata[:skip_create]
      @test_container_name = "test-container"
    else
      @test_container_name = create_test_container

      if example.metadata[:running] || example.metadata[:frozen]
        client.start_container(@test_container_name, sync: true)
      end

      if example.metadata[:frozen]
        client.freeze_container(@test_container_name, sync: true)
      end


      if example.metadata[:snapshot]
        client.create_snapshot(@test_container_name, "test-snapshot", sync: true)
      end

    end

  end

  config.after(:each, container: true) do |example|

    unless example.metadata[:skip_delete]

      container = client.container(@test_container_name)

      if container.status != "Stopped"
        client.stop_container(@test_container_name, force: true, sync: true)
      end

     delete_test_container(@test_container_name, image: example.metadata[:delete_image])

    end

  end

  config.before(:each, profile: true) do |example|
    @profile_name = "test-profile"

    unless example.metadata[:skip_create]
      client.create_profile(@profile_name, example.metadata[:profile_options] || {})
    end
  end

  config.after(:each, profile: true) do |example|
    unless example.metadata[:skip_delete]
      client.delete_profile(@profile_name)
    end
  end

  config.before(:each, profiles: true) do |example|
    1.upto(2) { |i| client.create_profile("test-profile#{i}") }
  end

  config.after(:each, profiles: true) do |example|
    1.upto(2) { |i| client.delete_profile("test-profile#{i}") }
  end

end

def ok_response
 { status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' } }
end

def accepted_response
 { status: 202, body: {}.to_json, headers: { 'Content-Type' => 'application/json' } }
end

def lxd
  client = Hyperkit::Client.new(
    api_endpoint: 'https://192.168.103.101:8443',
    verify_ssl: false,
    client_cert: File.join(fixture_path, "client.crt"),
    client_key: File.join(fixture_path, "client.key")
  )

  # TODO: Bug in constructor
  client.verify_ssl = false
  client
end

def lxd2
  client = Hyperkit::Client.new(
    api_endpoint: 'https://192.168.103.102:8443',
    verify_ssl: false,
    client_cert: File.join(fixture_path, "client.crt"),
    client_key: File.join(fixture_path, "client.key")
  )

  # TODO: Bug in constructor
  client.verify_ssl = false
  client
end

def remote_lxd
  Hyperkit::Client.new(api_endpoint: "https://images.linuxcontainers.org:8443")
end

# def local_client
#   client = Hyperkit::Client.new(api_endpoint: 'https://lxd.example.com:8443', verify_ssl: false)
#   # TODO: Bug in constructor
#   client.verify_ssl = false
#   client
# end
#

def create_test_container(name="test-container", extra_opts={})

  opts = extra_opts.dup

  if ! opts[:alias] && ! opts[:fingerprint] && ! opts[:properties] && ! opts[:empty]
    opts[:alias] = "cirros"
  end

  client.create_container(name, opts.merge(sync: true))
  name
end

def delete_test_container(name="test-container", opts={})

  container = client.container(name)

  if container.status != "Stopped"
    client.stop_container(name, force: true, sync: true)
  end

  client.delete_container(name, sync: true)

  if opts[:image] && container.config["volatile.base_image"]
    delete_test_image(container.config["volatile.base_image"])
  end

end

def create_test_image(alias_name=nil, options={})
  fingerprint = fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz")

  client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"), options.merge(sync: true))

  if alias_name
    client.create_image_alias(fingerprint, alias_name)
  end

  fingerprint
end

def delete_test_image(fingerprint = fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz"))
  client.delete_image(fingerprint, sync: true)
end

def create_remote_test_image(options={})
  @remote_cert = lxd2.get("/1.0").metadata.environment.certificate
  @remote_fingerprint = fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz")
  lxd2.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"), options.merge(sync: true))
  lxd2.create_image_alias(@remote_fingerprint, "busybox/default")
  @remote_fingerprint
end

def delete_remote_test_image
  lxd2.delete_image(@remote_fingerprint, sync: true)
end

def test_migration_source_data
  {
    architecture: "x86_64",
    config: {
      :"volatile.base_image"  => "test-base-image",
      :"volatile.eth0.hwaddr" => "test-eth0-hwaddr",
    },
    profiles: ["default"],
    websocket: {
      url: "test-ws-url",
      secrets: {
        control: "test-control-secret",
        fs: "test-fs-secret",
        criu: "test-criu-secret"
      }
    },
    certificate: "test-certificate"
  }
end

def test_migration_source(data={})
  data = test_migration_source_data if data.empty?
  Sawyer::Resource.new(Sawyer::Agent.new("testurl"), data)
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

def cert_fingerprint(cert)
  Digest::SHA256.hexdigest(OpenSSL::X509::Certificate.new(cert).to_der)
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
  Hyperkit::Client.new(verify_ssl: false, client_cert: nil, client_key: nil)
end

def test_cert
  read_fixture("test-cert.crt")
end

def test_cert_fingerprint
  cert_fingerprint(read_fixture("test-cert.crt"))
end

