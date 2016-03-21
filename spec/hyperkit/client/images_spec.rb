require 'spec_helper'

describe Hyperkit::Client::Images do

  let(:client) { Hyperkit::Client.new }

  describe ".images", :vcr do

    it "returns an array of images" do
      images = client.images
      expect(images).to be_kind_of(Array)
    end

    it "makes the correct API call" do
      images = client.images
      assert_requested :get, lxd_url("/1.0/images")
    end

    it "returns only the image fingerprints and not their paths" do
      body = { metadata: [
        "/1.0/images/54c8caac1f61901ed86c68f24af5f5d3672bdc62c71d04f06df3a59e95684473",
        "/1.0/images/97d97a3d1d053840ca19c86cdd0596cf1be060c5157d31407f2a4f9f350c78cc",
        "/1.0/images/a49d26ce5808075f5175bf31f5cb90561f5023dcd408da8ac5e834096d46b2d8",
        "/1.0/images/c9b6e738fae75286d52f497415463a8ecc61bbcb046536f220d797b0e500a41f"
			]}.to_json
      stub_get("/1.0/images").
        to_return(:status => 200, body: body, :headers => {'Content-Type' => 'application/json'})

      images = client.images
      expect(images).to eq(%w[
        54c8caac1f61901ed86c68f24af5f5d3672bdc62c71d04f06df3a59e95684473
        97d97a3d1d053840ca19c86cdd0596cf1be060c5157d31407f2a4f9f350c78cc
        a49d26ce5808075f5175bf31f5cb90561f5023dcd408da8ac5e834096d46b2d8
        c9b6e738fae75286d52f497415463a8ecc61bbcb046536f220d797b0e500a41f
      ])
    end

  end

  describe ".image", :vcr do

    it "retrieves a image" do
      client.api_endpoint = 'https://images.linuxcontainers.org:8443'
      images = client.images
      fingerprint = images.first

      image = client.image(fingerprint)
			expect(image[:fingerprint]).to eq(fingerprint)
    end

    it "makes the correct API call" do
			request = stub_get("/1.0/images/45bcc353f629b23ce30ef4cca14d2a4990c396d85ea68905795cc7579c145123").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.image("45bcc353f629b23ce30ef4cca14d2a4990c396d85ea68905795cc7579c145123")
      assert_requested request
    end

  end

  describe ".image_aliases", :vcr do

    it "returns an array of image aliases" do
      aliases = client.image_aliases
      expect(aliases).to be_kind_of(Array)
    end

    it "makes the correct API call" do
      aliases = client.image_aliases
      assert_requested :get, lxd_url("/1.0/images/aliases")
    end

    it "returns only the image aliases and not their paths" do
      body = { metadata: [
        "/1.0/images/aliases/ubuntu/xenial/amd64/default",
        "/1.0/images/aliases/ubuntu/xenial/amd64",
        "/1.0/images/aliases/ubuntu/xenial/armhf/default",
        "/1.0/images/aliases/ubuntu/xenial/armhf",
        "/1.0/images/aliases/ubuntu/xenial/i386/default",
        "/1.0/images/aliases/ubuntu/xenial/i386"
			]}.to_json
      stub_get("/1.0/images/aliases").
        to_return(:status => 200, body: body, :headers => {'Content-Type' => 'application/json'})

      aliases = client.image_aliases
      expect(aliases).to eq(%w[
        ubuntu/xenial/amd64/default
        ubuntu/xenial/amd64
        ubuntu/xenial/armhf/default
        ubuntu/xenial/armhf
        ubuntu/xenial/i386/default
        ubuntu/xenial/i386
      ])
    end

  end

  describe ".image_alias", :vcr do

    it "retrieves an alias" do
			image_alias = "ubuntu/xenial/amd64/default"
      client.api_endpoint = "https://images.linuxcontainers.org:8443"
      a = client.image_alias(image_alias)

			expect(a[:name]).to eq(image_alias)
      expect(a[:target]).to_not be_nil
    end

    it "makes the correct API call" do
			request = stub_get("/1.0/images/aliases/ubuntu/xenial/amd64/default").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.image_alias("ubuntu/xenial/amd64/default")
      assert_requested request
    end

  end

  describe ".create_image_alias", :vcr do

    it "creates an alias" do
      fingerprint = fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz")

			response = client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"))
      client.wait_for_operation(response[:id])

      client.create_image_alias(fingerprint, "busybox/default")

      image = client.image_by_alias("busybox/default")
      expect(image[:fingerprint]).to eq(fingerprint)

      client.delete_image(fingerprint)
    end

    it "accepts an alias description" do
      fingerprint = create_test_image
      client.create_image_alias(fingerprint, "busybox/default", description: "Hello world")

      a = client.image_alias("busybox/default")
      expect(a[:description]).to eq("Hello world")

      delete_test_image
    end

    it "makes the correct API call" do
			request = stub_post("/1.0/images/aliases").
        with(body: hash_including({
			  	name: "alias_name",
          target: "target_fingerprint",
          description: "desc"
        })).
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.create_image_alias("target_fingerprint", "alias_name", description: "desc")
      assert_requested request
    end

  end

  describe ".delete_image_alias", :vcr do

    it "deletes an alias" do
      fingerprint = create_test_image("busybox/default")
      image = client.image(fingerprint)

      expect(image[:aliases].map(&:name)).to include("busybox/default")

      client.delete_image_alias("busybox/default")
      image = client.image(fingerprint)

      expect(image[:aliases].map(&:name)).to_not include("busybox/default")

      delete_test_image
    end

    it "makes the correct API call" do
			request = stub_delete("/1.0/images/aliases/test").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.delete_image_alias("test")
      assert_requested request
    end

  end

  describe ".rename_image_alias", :vcr do

    it "renames an alias" do
      fingerprint = create_test_image("busybox/default")
      image = client.image(fingerprint)

      expect(image[:aliases].map(&:name)).to include("busybox/default")
      expect(image[:aliases].map(&:name)).to_not include("busybox/amd64")

      client.rename_image_alias("busybox/default", "busybox/amd64")
      image = client.image(fingerprint)

      expect(image[:aliases].map(&:name)).to_not include("busybox/default")
      expect(image[:aliases].map(&:name)).to include("busybox/amd64")

      delete_test_image
    end

    it "makes the correct API call" do
			request = stub_post("/1.0/images/aliases/test").
        with(body: hash_including({
          name: "test2"
         })).
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.rename_image_alias("test", "test2")
      assert_requested request
    end

  end

  describe ".image_by_alias", :vcr do
    it "retrieves an image by its alias" do
			image_alias = "ubuntu/xenial/amd64/default"
      client.api_endpoint = 'https://images.linuxcontainers.org:8443'
      image = client.image_by_alias(image_alias)

      expect(image[:aliases].any? { |a| a[:name] == image_alias }).to be_truthy
			expect(image[:properties][:description]).to include("Ubuntu xenial (amd64)")
			expect(image[:architecture]).to eq("x86_64")
    end

    it "makes the correct API calls" do
			image_alias = "ubuntu/xenial/amd64/default"
      fingerprint = "45bcc353f629b23ce30ef4cca14d2a4990c396d85ea68905795cc7579c145123"

			request1 = stub_get("/1.0/images/aliases/#{image_alias}").
        to_return(status: 200, body: { metadata: {target: fingerprint, name: image_alias}}.to_json, headers: { 'Content-Type' => 'application/json' })

			request2 = stub_get("/1.0/images/#{fingerprint}").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.image_by_alias(image_alias)
      assert_requested request1
      assert_requested request2
    end

  end

  describe ".create_image_from_file", :vcr do

    after do
      client.delete_image(@fingerprint) if @fingerprint
    end

    it "creates an image" do
      @fingerprint = fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz")

			response = client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"))
      client.wait_for_operation(response[:id])

      expect(client.images).to include(@fingerprint)
		end

    it "makes the correct API call" do
      request = stub_post("/1.0/images").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
			client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"))
      assert_requested request
    end

    context "when properties are passed" do
      it "stores them with the image" do
        @fingerprint = fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz")

        response = client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"),
					properties: { hello: "world %!@# how are you?!", test: 123 })
        client.wait_for_operation(response[:id])

        image = client.image(@fingerprint)

        expect(image[:properties][:hello]).to eq("world %!@# how are you?!")
        expect(image[:properties][:test]).to eq("123")
      end
    end

    context "when 'public': true is passed" do
      it "makes the image public" do
        @fingerprint = fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz")

        response = client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"), public: true)
        client.wait_for_operation(response[:id])

        image = client.image(@fingerprint)
        expect(image[:public]).to be_truthy
      end
    end

    context "when public: true is not passed" do
      it "defaults to a private image" do
        @fingerprint = fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz")

        response = client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"))
        client.wait_for_operation(response[:id])

        image = client.image(@fingerprint)
        expect(image[:public]).to be_falsy
      end
    end

    context "when a filename is passed" do
      it "passes the filename with the upload" do
        @fingerprint = fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz")

        response = client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"),
					filename: "test.tar.xz")
        client.wait_for_operation(response[:id])

        image = client.image(@fingerprint)
        expect(image[:filename]).to eq("test.tar.xz")
      end
    end

    context "when no filename is passed" do
      it "defaults to the name of the file being uploaded" do
        @fingerprint = fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz")

        response = client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"))
        client.wait_for_operation(response[:id])

        image = client.image(@fingerprint)
        expect(image[:filename]).to eq("busybox-1.21.1-amd64-lxc.tar.xz")
      end
    end

    context "when passed an optional fingerprint" do

      it "uploads successfully if the fingerprint matches the image fingerprint" do
        @fingerprint = fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz")

        response = client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"),
					fingerprint: @fingerprint)
        client.wait_for_operation(response[:id])

        expect(client.images).to include(@fingerprint)
      end

      it "throws an exception (when the operation is waited upon) if the fingerprint does not match the image fingerprint" do
        response = client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"),
					fingerprint: "bad-fingerprint")
        expect { client.wait_for_operation(response[:id]) }.to raise_error(Hyperkit::BadRequest)
        expect(client.images).to_not include(fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz"))
      end

    end

  end

  describe ".create_image_from_remote", :vcr do

    after do
      client.delete_image(@fingerprint) if @fingerprint
    end

    it "creates an image" do
      response = client.create_image_from_remote("https://images.linuxcontainers.org:8443",
				alias: "ubuntu/xenial/amd64")
      response = client.wait_for_operation(response[:id])
      @fingerprint = response[:metadata][:fingerprint]

      image = client.image(@fingerprint)

			expect(image[:architecture]).to eq("x86_64")
      expect(image[:public]).to eq(false)
      expect(image[:update_source][:server]).to eq("https://images.linuxcontainers.org:8443")
			expect(image[:update_source][:protocol]).to eq("lxd")

    end

    it "makes the correct API call" do
      request = stub_post("/1.0/images").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      client.create_image_from_remote("https://images.linuxcontainers.org:8443",
				alias: "ubuntu/xenial/amd64")
      assert_requested request
		end

    context "when properties are passed" do
      it "stores them with the image" do
      	response = client.create_image_from_remote("https://images.linuxcontainers.org:8443",
					alias: "ubuntu/xenial/amd64",
					properties: { hello: "world %!@# how are you?!", test: 123 }
				)
      	response = client.wait_for_operation(response[:id])
        @fingerprint = response[:metadata][:fingerprint]

        image = client.image(@fingerprint)

        expect(image[:properties][:hello]).to eq("world %!@# how are you?!")
        expect(image[:properties][:test]).to eq("123")
			end
    end
     
    context "when 'public': true is passed" do
      it "makes the image public" do
      	response = client.create_image_from_remote("https://images.linuxcontainers.org:8443",
					alias: "ubuntu/xenial/amd64", public: true)
      	response = client.wait_for_operation(response[:id])
        @fingerprint = response[:metadata][:fingerprint]

      	image = client.image(@fingerprint)
				expect(image[:public]).to be_truthy
      end
    end

    context "when public: true is not passed" do
      it "defaults to a private image" do
      	response = client.create_image_from_remote("https://images.linuxcontainers.org:8443",
					alias: "ubuntu/xenial/amd64")
      	response = client.wait_for_operation(response[:id])
        @fingerprint = response[:metadata][:fingerprint]

      	image = client.image(@fingerprint)
				expect(image[:public]).to be_falsy
      end
    end

    context "when a filename is passed" do
      it "passes the filename with the upload" do
      	response = client.create_image_from_remote("https://images.linuxcontainers.org:8443",
					alias: "ubuntu/xenial/amd64",
          filename: "ubuntu-xenial.tar.xz")
      	response = client.wait_for_operation(response[:id])
        @fingerprint = response[:metadata][:fingerprint]

      	image = client.image(@fingerprint)
				expect(image[:filename]).to eq("ubuntu-xenial.tar.xz")
      end
    end

    context "when passed an alias" do
      it "passes the alias as the image to download" do
        request = stub_post("/1.0/images").
          with(body: hash_including({:source => {
						type: "image",
            mode: "pull",
            server: "https://images.linuxcontainers.org:8443",
						alias: "ubuntu/xenial/amd64",
					}})).
          to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
			  	alias: "ubuntu/xenial/amd64")
        assert_requested request
			end
    end

    context "when passed a fingerprint" do
      it "passes the fingerprint as the image to download" do
        request = stub_post("/1.0/images").
          with(body: hash_including({:source => {
						type: "image",
            mode: "pull",
            server: "https://images.linuxcontainers.org:8443",
			  		fingerprint: "07d1a93ca98d3480b4b763c4defb9d05b082b764b1abac7a4dc00f482d6faf09"
					}})).
          to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
			    fingerprint: "07d1a93ca98d3480b4b763c4defb9d05b082b764b1abac7a4dc00f482d6faf09")
        assert_requested request
			end
		end

    context "when passed both an alias and fingerprint" do
      it "passes the alias as the image to download" do
        request = stub_post("/1.0/images").
          with(body: hash_including({:source => {
						type: "image",
            mode: "pull",
            server: "https://images.linuxcontainers.org:8443",
						alias: "ubuntu/xenial/amd64",
					}})).
          to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
			  	alias: "ubuntu/xenial/amd64",
			    fingerprint: "07d1a93ca98d3480b4b763c4defb9d05b082b764b1abac7a4dc00f482d6faf09")
        assert_requested request
			end
    end

    context "when passed neither an alias nor a fingerprint" do
      it "raises an error" do
				call = lambda { client.create_image_from_remote("https://images.linuxcontainers.org:8443") }
        expect(call).to raise_error(Hyperkit::ImageIdentifierRequired)
			end
    end

    context "when passed a protocol" do
      it "accepts lxd" do
        request = stub_post("/1.0/images").
          with(body: hash_including({:source => {
						type: "image",
            mode: "pull",
            server: "https://images.linuxcontainers.org:8443",
            protocol: "lxd",
						alias: "ubuntu/xenial/amd64",
					}})).
          to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
			  	alias: "ubuntu/xenial/amd64",
					protocol: "lxd")
        assert_requested request
			end

      it "accepts simplestreams" do
        request = stub_post("/1.0/images").
          with(body: hash_including({:source => {
						type: "image",
            mode: "pull",
            server: "https://images.linuxcontainers.org:8443",
            protocol: "simplestreams",
						alias: "ubuntu/xenial/amd64",
					}})).
          to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
			  	alias: "ubuntu/xenial/amd64",
					protocol: "simplestreams")
        assert_requested request
			end

      it "raises an error on invalid input" do
				call = lambda do
					client.create_image_from_remote("https://images.linuxcontainers.org:8443",
			  		alias: "ubuntu/xenial/amd64",
						protocol: "qwe")
				end
        expect(call).to raise_error(Hyperkit::InvalidProtocol)
			end

    end

    context "when passed a secret" do
      it "passes the secret to the server" do
        request = stub_post("/1.0/images").
          with(body: hash_including({:source => {
						type: "image",
            mode: "pull",
            server: "https://images.linuxcontainers.org:8443",
						secret: "reallysecret",
						alias: "ubuntu/xenial/amd64",
					}})).
          to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
			  	alias: "ubuntu/xenial/amd64",
					secret: "reallysecret")
        assert_requested request
			end
    end

    context "when passed a certificate" do
      it "passes the certificate to the server" do
        request = stub_post("/1.0/images").
          with(body: hash_including({:source => {
						type: "image",
            mode: "pull",
            server: "https://images.linuxcontainers.org:8443",
						certificate: test_cert2,
						alias: "ubuntu/xenial/amd64",
					}})).
          to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
			  	alias: "ubuntu/xenial/amd64",
					certificate: test_cert2)
        assert_requested request
      end
    end

    context "when 'auto_update': true is passed" do
      it "auto-updates the image" do
      	response = client.create_image_from_remote("https://images.linuxcontainers.org:8443",
					alias: "ubuntu/xenial/amd64", auto_update: true)
      	response = client.wait_for_operation(response[:id])
        @fingerprint = response[:metadata][:fingerprint]

      	image = client.image(@fingerprint)
				expect(image[:auto_update]).to be_truthy
      end
    end

    context "when auto_update: true is not passed" do
      it "defaults to a non-auto-updated image" do
      	response = client.create_image_from_remote("https://images.linuxcontainers.org:8443",
					alias: "ubuntu/xenial/amd64")
      	response = client.wait_for_operation(response[:id])
        @fingerprint = response[:metadata][:fingerprint]

      	image = client.image(@fingerprint)
				expect(image[:auto_update]).to be_falsy
      end
    end

  end

  describe ".create_image_from_url", :vcr do

    after do
      client.delete_image(@fingerprint) if @fingerprint
    end

    it "creates an image" do
      response = client.create_image_from_url("http://www.csd.uwo.ca/~jeff/containers/busybox")
      response = client.wait_for_operation(response[:id])

      @fingerprint = response[:metadata][:fingerprint]
      image = client.image(@fingerprint)

			expect(image[:architecture]).to eq("x86_64")
      expect(image[:public]).to eq(false)
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/images").
        with(body: hash_including({:source => {
						type: "url",
            url: "http://www.csd.uwo.ca/~jeff/containers/busybox"
					}})).
          to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      client.create_image_from_url("http://www.csd.uwo.ca/~jeff/containers/busybox")
      assert_requested request
		end

    context "when properties are passed" do
      it "stores them with the image" do
        response = client.create_image_from_url("http://www.csd.uwo.ca/~jeff/containers/busybox",
					properties: { hello: "world %!@# how are you?!", test: 123 })
      	response = client.wait_for_operation(response[:id])

        @fingerprint = response[:metadata][:fingerprint]
        image = client.image(@fingerprint)

        expect(image[:properties][:hello]).to eq("world %!@# how are you?!")
        expect(image[:properties][:test]).to eq("123")
			end
    end
     
    context "when 'public': true is passed" do
      it "makes the image public" do
        response = client.create_image_from_url("http://www.csd.uwo.ca/~jeff/containers/busybox",
					public: true)
      	response = client.wait_for_operation(response[:id])

        @fingerprint = response[:metadata][:fingerprint]
        image = client.image(@fingerprint)

			  expect(image[:public]).to be_truthy
      end
    end

    context "when public: true is not passed" do
      it "defaults to a private image" do
        response = client.create_image_from_url("http://www.csd.uwo.ca/~jeff/containers/busybox")
      	response = client.wait_for_operation(response[:id])

        @fingerprint = response[:metadata][:fingerprint]
        image = client.image(@fingerprint)

			  expect(image[:public]).to be_falsy
      end
    end

    context "when a filename is passed" do
      it "stores the filename with the imported image" do
        response = client.create_image_from_url("http://www.csd.uwo.ca/~jeff/containers/busybox",
					filename: "busybox-v1.tar.xz")
      	response = client.wait_for_operation(response[:id])

        @fingerprint = response[:metadata][:fingerprint]
        image = client.image(@fingerprint)

			  expect(image[:filename]).to eq("busybox-v1.tar.xz")
      end
    end

  end

  describe ".create_image_from_container", :vcr do

		before do
      # TODO: create the test container
		end

    after do
      client.delete_image(@fingerprint) if @fingerprint
      # TODO: delete the test container
    end

    it "creates an image" do
      response = client.create_image_from_container("test-container")
      response = client.wait_for_operation(response[:id])

      @fingerprint = response[:metadata][:fingerprint]
      image = client.image(@fingerprint)

			expect(image[:architecture]).to eq("x86_64")
      expect(image[:public]).to eq(false)
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/images").
        with(body: hash_including({:source => {
						type: "container",
            name: "test-container"
					}})).
          to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      client.create_image_from_container("test-container")
      assert_requested request
		end

    context "when properties are passed" do
      it "stores them with the image" do
        response = client.create_image_from_container("test-container",
					properties: { hello: "world %!@# how are you?!", test: 123 })
      	response = client.wait_for_operation(response[:id])

        @fingerprint = response[:metadata][:fingerprint]
        image = client.image(@fingerprint)

        expect(image[:properties][:hello]).to eq("world %!@# how are you?!")
        expect(image[:properties][:test]).to eq("123")
			end
    end
     
    context "when 'public': true is passed" do
      it "makes the image public" do
        response = client.create_image_from_container("test-container", public: true)
      	response = client.wait_for_operation(response[:id])

        @fingerprint = response[:metadata][:fingerprint]
        image = client.image(@fingerprint)

			  expect(image[:public]).to be_truthy
      end
    end

    context "when public: true is not passed" do
      it "defaults to a private image" do
        response = client.create_image_from_container("test-container")
      	response = client.wait_for_operation(response[:id])

        @fingerprint = response[:metadata][:fingerprint]
        image = client.image(@fingerprint)

			  expect(image[:public]).to be_falsy
      end
    end

    context "when a filename is passed" do
      it "stores the filename with the imported image" do
        response = client.create_image_from_container("test-container", filename: "busybox-v1.tar.xz")
      	response = client.wait_for_operation(response[:id])

        @fingerprint = response[:metadata][:fingerprint]
        image = client.image(@fingerprint)

			  expect(image[:filename]).to eq("busybox-v1.tar.xz")
      end
    end

	end

  describe ".create_image_from_snapshot", :vcr do

		before do
      # TODO: create the test snapshot
		end

    after do
			client.delete_image(@fingerprint) if @fingerprint
      # TODO: delete the test snapshot
		end

    it "creates an image" do
      response = client.create_image_from_snapshot("test-container", "snapshot1")
      response = client.wait_for_operation(response[:id])

      @fingerprint = response[:metadata][:fingerprint]
      image = client.image(@fingerprint)

			expect(image[:architecture]).to eq("x86_64")
      expect(image[:public]).to eq(false)
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/images").
        with(body: hash_including({:source => {
						type: "snapshot",
            name: "test-container/snapshot1"
					}})).
          to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      client.create_image_from_snapshot("test-container", "snapshot1")
      assert_requested request
		end

    context "when properties are passed" do
      it "stores them with the image" do
        response = client.create_image_from_snapshot("test-container", "snapshot1",
					properties: { hello: "world %!@# how are you?!", test: 123 })
      	response = client.wait_for_operation(response[:id])

        @fingerprint = response[:metadata][:fingerprint]
        image = client.image(@fingerprint)

        expect(image[:properties][:hello]).to eq("world %!@# how are you?!")
        expect(image[:properties][:test]).to eq("123")
			end
    end
     
    context "when 'public': true is passed" do
      it "makes the image public" do
        response = client.create_image_from_snapshot("test-container", "snapshot1", public: true)
      	response = client.wait_for_operation(response[:id])

        @fingerprint = response[:metadata][:fingerprint]
        image = client.image(@fingerprint)

			  expect(image[:public]).to be_truthy
      end
    end

    context "when public: true is not passed" do
      it "defaults to a private image" do
        response = client.create_image_from_snapshot("test-container", "snapshot1")
      	response = client.wait_for_operation(response[:id])

        @fingerprint = response[:metadata][:fingerprint]
        image = client.image(@fingerprint)

			  expect(image[:public]).to be_falsy
      end
    end

    context "when a filename is passed" do
      it "stores the filename with the imported image" do
        response = client.create_image_from_snapshot("test-container", "snapshot1",
					filename: "busybox-v1.tar.xz")
      	response = client.wait_for_operation(response[:id])

        @fingerprint = response[:metadata][:fingerprint]
        image = client.image(@fingerprint)

			  expect(image[:filename]).to eq("busybox-v1.tar.xz")
      end
    end
	end

  describe ".delete_image", :vcr do

    it "deletes an existing image" do
        response = client.create_image_from_snapshot("test-container", "snapshot1")
      	response = client.wait_for_operation(response[:id])
        fingerprint = response[:metadata][:fingerprint]

        expect(client.images).to include(fingerprint)
        client.delete_image(fingerprint)
        expect(client.images).to_not include(fingerprint)
    end

    it "makes the correct API call" do
      request = stub_delete("/1.0/images/test").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      client.delete_image("test")
      assert_requested request
    end

  end

end

