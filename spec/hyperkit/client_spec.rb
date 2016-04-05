require 'spec_helper'
require 'json'

describe Hyperkit::Client do

  describe "module configuration" do

    before do
      Hyperkit.configure do |config|
        Hyperkit::Configurable.keys.each do |key|
          config.send("#{key}=", "Some #{key}")
        end
      end
    end

    it "inherits the module configuration" do
      client = Hyperkit::Client.new
      Hyperkit::Configurable.keys.each do |key|
        expect(client.instance_variable_get(:"@#{key}")).to eq("Some #{key}")
      end
    end

    describe "with class level configuration" do

      before do
        @opts = {
          :client_cert => '/tmp/cert',
          :client_key => '/tmp/key'
        }
      end

      it "overrides module configuration" do
        client = Hyperkit::Client.new(@opts)
        expect(client.client_cert).to eq('/tmp/cert')
        expect(client.client_key).to eq('/tmp/key')
      end

      it "can set configuration after initialization" do
        client = Hyperkit::Client.new
        client.configure do |config|
          @opts.each do |key, value|
            config.send("#{key}=", value)
          end
        end
        expect(client.client_cert).to eq('/tmp/cert')
        expect(client.client_key).to eq('/tmp/key')
      end

      #TODO: Uncomment when trust passwords supported
      #it "masks passwords on inspect" do
      #  client = Hyperkit::Client.new(@opts)
      #  inspected = client.inspect
      #  expect(inspected).not_to include("il0veruby")
      #end

    end

  end

  describe "content type" do
    it "sets a default Content-Type header" do
      profile_request = stub_post("/1.0/profiles").
        with({
          :headers => {"Content-Type" => "application/json"}})

      Hyperkit.client.post "/1.0/profiles", {}
      assert_requested profile_request
    end
  end

  describe "authentication" do
    before do
      @client = Hyperkit.client
    end

    describe "with module level config" do
      it "sets client credentials with .configure" do
        Hyperkit.configure do |config|
          config.client_cert = '/tmp/cert'
          config.client_key = '/tmp/key'
        end
        expect(Hyperkit.client.client_cert).to eq('/tmp/cert')
        expect(Hyperkit.client.client_key).to eq('/tmp/key')
      end
      it "sets client credentials with module methods" do
        Hyperkit.client_cert = '/tmp/cert'
        Hyperkit.client_key = '/tmp/key'
        expect(Hyperkit.client.client_cert).to eq('/tmp/cert')
        expect(Hyperkit.client.client_key).to eq('/tmp/key')
      end
    end

    describe "with class level config" do
      it "sets client credentials with .configure" do
        @client.configure do |config|
          config.client_cert = '/tmp/cert'
          config.client_key = '/tmp/key'
        end
        expect(@client.client_cert).to eq('/tmp/cert')
        expect(@client.client_key).to eq('/tmp/key')
      end
      it "sets client credentials with instance methods" do
        @client.client_cert = '/tmp/cert'
        @client.client_key = '/tmp/key'
        expect(@client.client_cert).to eq('/tmp/cert')
        expect(@client.client_key).to eq('/tmp/key')
      end
    end

  end

  describe ".agent" do
    it "acts like a Sawyer agent" do
      expect(Hyperkit.client.agent).to respond_to :start
    end
    it "caches the agent" do
      agent = Hyperkit.client.agent
      expect(agent.object_id).to eq(Hyperkit.client.agent.object_id)
    end
  end # .agent

  describe ".root" do
    it "fetches the API root" do
      VCR.use_cassette 'root' do
        root = Hyperkit.client.root
        expect(root[:metadata]).to eq(['/1.0'])
      end
    end
  end # .root

  describe ".last_response", :vcr do
    it "caches the last agent response" do
      client = Hyperkit::Client.new(api_endpoint: 'https://192.168.103.101:8443', verify_ssl: false)
      expect(client.last_response).to be_nil
      client.get "/"
      expect(client.last_response.status).to eq(200)
    end
  end # .last_response

  describe ".get", :vcr do
    it "handles query params" do
      Hyperkit.get "/", :foo => "bar"
      assert_requested :get, "https://192.168.103.101:8443?foo=bar"
    end
    it "handles headers" do
      request = stub_get("/zen").
        with(:query => {:foo => "bar"}, :headers => {:accept => "text/plain"})
      Hyperkit.get "/zen", :foo => "bar", :accept => "text/plain"
      assert_requested request
    end
  end # .get

  describe ".head", :vcr do
    it "handles query params" do
      Hyperkit.head "/", :foo => "bar"
      assert_requested :head, "https://192.168.103.101:8443?foo=bar"
    end
    it "handles headers" do
      request = stub_head("/zen").
        with(:query => {:foo => "bar"}, :headers => {:accept => "text/plain"})
      Hyperkit.head "/zen", :foo => "bar", :accept => "text/plain"
      assert_requested request
    end
  end # .head

  describe "when making requests" do
    before do
      @client = Hyperkit.client
    end
    it "Accepts application/json by default" do
      VCR.use_cassette 'root' do
        root_request = stub_get("/").
          with(:headers => {:accept => "application/json"})
        @client.get "/"
        assert_requested root_request
        expect(@client.last_response.status).to eq(200)
      end
    end
    it "allows Accept'ing another media type" do
      root_request = stub_get("/").
        with(:headers => {:accept => "application/vnd.lxd.beta.diff+json"})
      @client.get "/", :accept => "application/vnd.lxd.beta.diff+json"
      assert_requested root_request
      expect(@client.last_response.status).to eq(200)
    end
    it "sets a default user agent" do
      root_request = stub_get("/").
        with(:headers => {:user_agent => Hyperkit::Default.user_agent})
      @client.get "/"
      assert_requested root_request
      expect(@client.last_response.status).to eq(200)
    end
    it "sets a custom user agent" do
      user_agent = "Mozilla/5.0 I am Spartacus!"
      root_request = stub_get("/").
        with(:headers => {:user_agent => user_agent})
      client = Hyperkit::Client.new(:user_agent => user_agent)
      client.get "/"
      assert_requested root_request
      expect(client.last_response.status).to eq(200)
    end
    it "sets a proxy server" do
      Hyperkit.configure do |config|
        config.proxy = 'http://proxy.example.com:80'
      end
      conn = Hyperkit.client.send(:agent).instance_variable_get(:"@conn")
      expect(conn.proxy[:uri].to_s).to eq('http://proxy.example.com')
    end
    it "passes along request headers for POST" do
      headers = {"X-LXD-Foo" => "bar"}
      root_request = stub_post("/").
        with(:headers => headers).
        to_return(:status => 201)
      client = Hyperkit::Client.new
      client.post "/", :headers => headers
      assert_requested root_request
      expect(client.last_response.status).to eq(201)
    end
  end

  describe "redirect handling" do
    it "follows redirect for 301 response" do
      client = Hyperkit::Client.new

      original_request = stub_get("/foo").
        to_return(:status => 301, :headers => { "Location" => "/bar" })
      redirect_request = stub_get("/bar").to_return(:status => 200)

      client.get("/foo")
      assert_requested original_request
      assert_requested redirect_request
    end

    it "follows redirect for 302 response" do
      client = Hyperkit::Client.new

      original_request = stub_get("/foo").
        to_return(:status => 302, :headers => { "Location" => "/bar" })
      redirect_request = stub_get("/bar").to_return(:status => 200)

      client.get("/foo")
      assert_requested original_request
      assert_requested redirect_request
    end

    it "follows redirect for 307 response" do
      client = Hyperkit::Client.new

      original_request = stub_post(lxd_url("/foo")).
        with(:body => { :some_property => "some_value" }.to_json).
        to_return(:status => 307, :headers => { "Location" => "/bar" })
      redirect_request = stub_post(lxd_url("/bar")).
        with(:body => { :some_property => "some_value" }.to_json).
        to_return(:status => 201, :headers => { "Location" => "/bar" })

      client.post("/foo", { :some_property => "some_value" })
      assert_requested original_request
      assert_requested redirect_request
    end

    it "follows redirects for supported HTTP methods" do
      client = Hyperkit::Client.new

      http_methods = [:head, :get, :post, :put, :patch, :delete]

      http_methods.each do |http|
        original_request = stub_request(http, lxd_url("/foo")).
          to_return(:status => 301, :headers => { "Location" => "/bar" })
        redirect_request = stub_request(http, lxd_url("/bar")).
          to_return(:status => 200)

        client.send(http, "/foo")
        assert_requested original_request
        assert_requested redirect_request
      end
    end

    it "does not change HTTP method when following a redirect" do
      client = Hyperkit::Client.new

      original_request = stub_delete("/foo").
        to_return(:status => 301, :headers => { "Location" => "/bar" })
      redirect_request = stub_delete("/bar").to_return(:status => 200)

      client.delete("/foo")
      assert_requested original_request
      assert_requested redirect_request

      other_methods = [:head, :get, :post, :put, :patch]
      other_methods.each do |http|
        assert_not_requested http, lxd_url("/bar")
      end
    end

    it "follows at most 3 consecutive redirects" do
      client = Hyperkit::Client.new

      original_request = stub_get("/a").
        to_return(:status => 302, :headers => { "Location" => "/b" })
      first_redirect = stub_get("/b").
        to_return(:status => 302, :headers => { "Location" => "/c" })
      second_redirect = stub_get("/c").
        to_return(:status => 302, :headers => { "Location" => "/d" })
      third_redirect = stub_get("/d").
        to_return(:status => 302, :headers => { "Location" => "/e" })
      fourth_redirect = stub_get("/e").to_return(:status => 200)

      expect { client.get("/a") }.to raise_error(Hyperkit::Middleware::RedirectLimitReached)
      assert_requested original_request
      assert_requested first_redirect
      assert_requested second_redirect
      assert_requested third_redirect
      assert_not_requested fourth_redirect
    end
  end

  context "error handling" do
    before do
      VCR.turn_off!
    end

    after do
      VCR.turn_on!
    end

    it "raises on 404" do
      stub_get('/booya').to_return(:status => 404)
      expect { Hyperkit.get('/booya') }.to raise_error Hyperkit::NotFound
    end

    it "raises on 500" do
      stub_get('/boom').to_return(:status => 500)
      expect { Hyperkit.get('/boom') }.to raise_error Hyperkit::InternalServerError
    end

    it "includes a message" do
      stub_get('/boom').
        to_return \
        :status => 422,
        :headers => {
          :content_type => "application/json",
        },
        :body => {:message => "Go away"}.to_json
      begin
        Hyperkit.get('/boom')
      rescue Hyperkit::UnprocessableEntity => e
        expect(e.message).to include("GET https://192.168.103.101:8443/boom: 422 - Go away")
      end
    end

    it "includes an error" do
      stub_get('/boom').
        to_return \
        :status => 422,
        :headers => {
          :content_type => "application/json",
        },
        :body => {:error => "Go away"}.to_json
      begin
        Hyperkit.get('/boom')
      rescue Hyperkit::UnprocessableEntity => e
        expect(e.message).to include("GET https://192.168.103.101:8443/boom: 422 - Error: Go away")
      end
    end

    it "includes an error summary" do
      stub_get('/boom').
        to_return \
        :status => 422,
        :headers => {
          :content_type => "application/json",
        },
        :body => {
          :message => "Go away",
          :errors => [
            :seriously => "Get out of here",
            :no_really => "Leave now"
          ]
        }.to_json
      begin
        Hyperkit.get('/boom')
      rescue Hyperkit::UnprocessableEntity => e
        expect(e.message).to include("GET https://192.168.103.101:8443/boom: 422 - Go away")
        expect(e.message).to include("  seriously: Get out of here")
        expect(e.message).to include("  no_really: Leave now")
      end
    end

    it "exposes errors array" do
      stub_get('/boom').
        to_return \
        :status => 422,
        :headers => {
          :content_type => "application/json",
        },
        :body => {
          :message => "Go away",
          :errors => [
            :seriously => "Get out of here",
            :no_really => "Leave now"
          ]
        }.to_json
      begin
        Hyperkit.get('/boom')
      rescue Hyperkit::UnprocessableEntity => e
        expect(e.errors.first[:seriously]).to eq("Get out of here")
        expect(e.errors.first[:no_really]).to eq("Leave now")
      end
    end

    it "raises on asynchronous errors" do
      stub_get('/boom').
        to_return \
        :status => 200,
        :headers => {
          :content_type => "application/json",
        },
        :body => {
          metadata: {
			      id: "e81ee5e8-6cce-46fd-b010-2c595ca66ed2",
		 	      class: "task",
		 	      created_at: Time.parse("2016-03-21 11:00:21 -0400"),
		 	      updated_at: Time.parse("2016-03-21 11:00:21 -0400"),
		 	      status: "Failure",
		 	      status_code: 400,
		 	      resources: nil,
		 	      metadata: nil,
		 	      may_cancel: false,
		 	      err:
		        "The image already exists: c22e4941ad01ef4b5e69908b7de21105e06b8ac7a31e1ccd153826a3b15ee1ba"
		      }
        }.to_json
      begin
        Hyperkit.get('/boom')
      rescue Hyperkit::BadRequest=> e
        expect(e.message).to include("400 - Error: The image already exists")
      end

    end
    it "raises on unknown client errors" do
      stub_get('/user').to_return \
        :status => 418,
        :headers => {
          :content_type => "application/json",
        },
        :body => {:message => "I'm a teapot"}.to_json
      expect { Hyperkit.get('/user') }.to raise_error Hyperkit::ClientError
    end

    it "raises on unknown server errors" do
      stub_get('/user').to_return \
        :status => 509,
        :headers => {
          :content_type => "application/json",
        },
        :body => {:message => "Bandwidth exceeded"}.to_json
      expect { Hyperkit.get('/user') }.to raise_error Hyperkit::ServerError
    end

    it "handles documentation URLs in error messages" do
      stub_get('/user').to_return \
        :status => 415,
        :headers => {
          :content_type => "application/json",
        },
        :body => {
          :message => "Unsupported Media Type",
          :documentation_url => "http://developer.github.com/v3"
        }.to_json
      begin
        Hyperkit.get('/user')
      rescue Hyperkit::UnsupportedMediaType => e
        msg = "415 - Unsupported Media Type"
        expect(e.message).to include(msg)
        expect(e.documentation_url).to eq("http://developer.github.com/v3")
      end
    end

    it "handles an error response with an array body" do
      stub_get('/user').to_return \
        :status => 500,
        :headers => {
          :content_type => "application/json"
        },
        :body => [].to_json
      expect { Hyperkit.get('/user') }.to raise_error Hyperkit::ServerError
    end
  end
end
