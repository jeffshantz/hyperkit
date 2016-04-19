require 'spec_helper'
require 'tmpdir'

describe Hyperkit::Client::Images do

  let(:client) { lxd }

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
      ]}

      stub_get("/1.0/images").
        to_return(ok_response.merge(body: body.to_json))

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

    it "retrieves a image", :image do
      image = client.image(@fingerprint)
      expect(image.fingerprint).to eq(@fingerprint)
      expect(image.architecture).to eq("x86_64")
    end

    it "accepts a prefix of an image fingerprint", :image do
      image = client.image(@fingerprint[0..2])
      expect(image.fingerprint).to eq(@fingerprint)
      expect(image.architecture).to eq("x86_64")
    end

    it "makes the correct API call" do
      request = stub_get("/1.0/images/45bcc353f629b23ce30ef4cca14d2a4990c396d85ea68905795cc7579c145123").
        to_return(ok_response)

      client.image("45bcc353f629b23ce30ef4cca14d2a4990c396d85ea68905795cc7579c145123")
      assert_requested request
    end

    it "accepts a secret" do

      request = stub_get("/1.0/images/45bcc353f629b23ce30ef4cca14d2a4990c396d85ea68905795cc7579c145123?secret=shhhh").
        to_return(ok_response)

      client.image("45bcc353f629b23ce30ef4cca14d2a4990c396d85ea68905795cc7579c145123",
        secret: "shhhh")

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
      ]}
      stub_get("/1.0/images/aliases").
        to_return(ok_response.merge(body: body.to_json))

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

      expect(a.name).to eq(image_alias)
      expect(a.target).to_not be_nil
    end

    it "makes the correct API call" do
      request = stub_get("/1.0/images/aliases/ubuntu/xenial/amd64/default").
        to_return(ok_response)

      client.image_alias("ubuntu/xenial/amd64/default")
      assert_requested request
    end

  end

  describe ".create_image_alias", :vcr do

    it "creates an alias", :image do
      client.create_image_alias(@fingerprint, "busybox/test")
      image = client.image_by_alias("busybox/test")
      expect(image.fingerprint).to eq(@fingerprint)
    end

    it "accepts an alias description", :image do
      client.create_image_alias(@fingerprint, "busybox/test", description: "Hello world")
      a = client.image_alias("busybox/test")
      expect(a.description).to eq("Hello world")
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/images/aliases").
        with(body: hash_including({
          name: "alias_name",
          target: "target_fingerprint",
          description: "desc"
        })).
        to_return(ok_response)

      client.create_image_alias("target_fingerprint", "alias_name", description: "desc")
      assert_requested request
    end

  end

  describe ".delete_image_alias", :vcr do

    it "deletes an alias", :image do
      image = client.image(@fingerprint)
      expect(image.aliases.map(&:name)).to include("busybox/default")

      client.delete_image_alias("busybox/default")
      image = client.image(@fingerprint)

      expect(image.aliases.map(&:name)).to_not include("busybox/default")
    end

    it "makes the correct API call" do
      request = stub_delete("/1.0/images/aliases/test").
        to_return(ok_response)

      client.delete_image_alias("test")
      assert_requested request
    end

  end

  describe ".rename_image_alias", :vcr do

    it "renames an alias", :image do
      image = client.image(@fingerprint)

      expect(image.aliases.map(&:name)).to include("busybox/default")
      expect(image.aliases.map(&:name)).to_not include("busybox/amd64")

      client.rename_image_alias("busybox/default", "busybox/amd64")
      image = client.image(@fingerprint)

      expect(image.aliases.map(&:name)).to_not include("busybox/default")
      expect(image.aliases.map(&:name)).to include("busybox/amd64")
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/images/aliases/test").
        with(body: hash_including({
          name: "test2"
         })).
        to_return(ok_response)

      client.rename_image_alias("test", "test2")
      assert_requested request
    end

  end

  describe ".update_image_alias", :vcr do

    it "updates an existing alias target" do

      stub_get("/1.0/images/aliases/test").
        to_return(ok_response.merge(body: {
          metadata: {
            target: "fingerprint",
            description: "test-description"
          }
        }.to_json))

      request = stub_put("/1.0/images/aliases/test").
        with(body: hash_including({
          target: "test-fingerprint",
          description: "test-description"
         })).
        to_return(ok_response)

      client.update_image_alias("test", target: "test-fingerprint")
      assert_requested request
    end

    it "updates an existing alias description", :image do
      image = client.image(@fingerprint)

      a = client.image_alias("busybox/default")
      expect(a.description).to be_empty

      client.update_image_alias("busybox/default", description: "hello")

      a = client.image_alias("busybox/default")
      expect(a.description).to eq("hello")
    end

    it "raises an error if no target or description is specified" do
      expect { client.update_image_alias("busybox/default") }.to raise_error(Hyperkit::AliasAttributesRequired)
    end

  end

  describe ".image_by_alias", :vcr do

    it "retrieves an image by its alias" do
      image = client.image_by_alias("cirros")
      expect(image.aliases.any? { |a| a.name == "cirros" }).to be_truthy
      expect(image.properties.description).to eq("Cirros 0.3.4 x86_64")
      expect(image.architecture).to eq("x86_64")
    end

    it "makes the correct API calls" do
      image_alias = "ubuntu/xenial/amd64/default"
      fingerprint = "45bcc353f629b23ce30ef4cca14d2a4990c396d85ea68905795cc7579c145123"

      request1 = stub_get("/1.0/images/aliases/#{image_alias}").
        to_return(ok_response.merge(body: { metadata: { target: fingerprint, name: image_alias } }.to_json))

      request2 = stub_get("/1.0/images/#{fingerprint}").
        to_return(ok_response)

      client.image_by_alias(image_alias)
      assert_requested request1
      assert_requested request2
    end

    it "accepts a secret" do
      image_alias = "ubuntu/xenial/amd64/default"
      fingerprint = "45bcc353f629b23ce30ef4cca14d2a4990c396d85ea68905795cc7579c145123"

      request1 = stub_get("/1.0/images/aliases/#{image_alias}").
        to_return(ok_response.merge(body: { metadata: { target: fingerprint, name: image_alias } }.to_json))

      request2 = stub_get("/1.0/images/#{fingerprint}?secret=shhhh").
        to_return(ok_response)

      client.image_by_alias(image_alias, secret: "shhhh")
      assert_requested request1
      assert_requested request2

    end

  end

  describe ".create_image_from_file", :vcr do

    it_behaves_like "an asynchronous operation" do

      after(:each) { delete_test_image(fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz")) }

      let(:operation) do
        lambda { |options| client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"), options) }
      end

    end

    before(:each, skip_create: true) do
      @fingerprint = fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz")
    end

    it "creates an image", :image, :skip_create do
      client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"))
      expect(client.images).to include(@fingerprint)
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/images").to_return(ok_response)
      client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"), sync: false)
      assert_requested request
    end

    context "when properties are passed" do

      it "stores them with the image", :image, :skip_create do
        client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"),
          properties: { hello: "world %!@# how are you?!", test: 123 })

        image = client.image(@fingerprint)

        expect(image.properties.hello).to eq("world %!@# how are you?!")
        expect(image.properties.test).to eq("123")
      end

    end

    context "when 'public': true is passed" do

      it "makes the image public", :image, :skip_create do
        client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"), public: true)
        image = client.image(@fingerprint)
        expect(image.public).to be_truthy
      end

    end

    context "when public: true is not passed" do

      it "defaults to a private image", :image, :skip_create do
        client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"))
        image = client.image(@fingerprint)
        expect(image.public).to be_falsy
      end

    end

    context "when a filename is passed" do

      it "passes the filename with the upload", :image, :skip_create do

        client.create_image_from_file(
          fixture("busybox-1.21.1-amd64-lxc.tar.xz"),
          filename: "test.tar.xz"
        )

        image = client.image(@fingerprint)
        expect(image.filename).to eq("test.tar.xz")

      end

    end

    context "when no filename is passed" do

      it "defaults to the name of the file being uploaded", :image, :skip_create do
        client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"))
        image = client.image(@fingerprint)
        expect(image.filename).to eq("busybox-1.21.1-amd64-lxc.tar.xz")
      end

    end

    context "when passed an optional fingerprint" do

      it "uploads successfully if the fingerprint matches the image fingerprint", :image, :skip_create do

        client.create_image_from_file(
          fixture("busybox-1.21.1-amd64-lxc.tar.xz"),
          fingerprint: @fingerprint)

        expect(client.images).to include(@fingerprint)
      end

      it "throws an exception (when the operation is waited upon) if the fingerprint does not match the image fingerprint" do
        call = lambda do
          client.create_image_from_file(fixture("busybox-1.21.1-amd64-lxc.tar.xz"),
            fingerprint: "bad-fingerprint")
        end
        expect(call).to raise_error(Hyperkit::BadRequest)
        expect(client.images).to_not include(fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz"))
      end

    end

  end

  describe ".create_image_from_remote", :vcr do

    it_behaves_like "an asynchronous operation" do

      before(:each) do
        create_remote_test_image(public: true)
      end

      after(:each) do
        delete_remote_test_image
        delete_test_image
      end

      let(:operation) do
        lambda do |options|
          res = client.create_image_from_remote("https://192.168.103.102:8443",
            {
              fingerprint: fixture_fingerprint("busybox-1.21.1-amd64-lxc.tar.xz"),
              certificate: @remote_cert
            }.merge(options))
        end

      end

    end

    it "creates an image", :remote_image, :image, :skip_create do

      response = client.create_image_from_remote(
        "https://192.168.103.102:8443",
        alias: "busybox/default",
        certificate: @remote_cert)

      @fingerprint = response.metadata.fingerprint
      image = client.image(@fingerprint)

      expect(image.architecture).to eq("x86_64")
      expect(image.public).to eq(false)
      expect(image.update_source.server).to eq("https://192.168.103.102:8443")
      expect(image.update_source.protocol).to eq("lxd")
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/images").
        to_return(ok_response)
      client.create_image_from_remote("https://images.linuxcontainers.org:8443",
        alias: "ubuntu/xenial/amd64", sync: false)
      assert_requested request
    end

    context "when properties are passed" do

      it "stores them with the image", :remote_image, :image, :skip_create do
        response = client.create_image_from_remote(
          "https://192.168.103.102:8443",
          alias: "busybox/default",
          properties: { hello: "world %!@# how are you?!", test: 123 },
          certificate: @remote_cert)

        @fingerprint = response.metadata.fingerprint
        image = client.image(@fingerprint)

        expect(image.properties.hello).to eq("world %!@# how are you?!")
        expect(image.properties.test).to eq("123")
      end

    end

    context "when 'public': true is passed" do

      it "makes the image public", :remote_image, :image, :skip_create do

        response = client.create_image_from_remote(
          "https://192.168.103.102:8443",
          alias: "busybox/default",
          public: true,
          certificate: @remote_cert)

        @fingerprint = response.metadata.fingerprint
        image = client.image(@fingerprint)

        expect(image.public).to be_truthy
      end

    end

    context "when public: true is not passed" do

      it "defaults to a private image", :remote_image, :image, :skip_create do

        response = client.create_image_from_remote(
          "https://192.168.103.102:8443",
          alias: "busybox/default",
          certificate: @remote_cert)

        @fingerprint = response.metadata.fingerprint
        image = client.image(@fingerprint)

        expect(image.public).to be_falsy
      end

    end

    context "when a filename is passed" do

      it "passes the filename with the upload", :remote_image, :image, :skip_create do

        response = client.create_image_from_remote(
          "https://192.168.103.102:8443",
          alias: "busybox/default",
          certificate: @remote_cert,
          filename: "test-busybox-archive.tar.xz")

        @fingerprint = response.metadata.fingerprint
        image = client.image(@fingerprint)

        expect(image.filename).to eq("test-busybox-archive.tar.xz")
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
          to_return(ok_response)

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
          alias: "ubuntu/xenial/amd64",
          sync: false)

        assert_requested request
      end

    end

    context "when passed a fingerprint" do

      it "passes the fingerprint as the image to download" do

        request = stub_post("/1.0/images").
          with(body: hash_including({source: {
            type: "image",
            mode: "pull",
            server: "https://images.linuxcontainers.org:8443",
            fingerprint: "07d1a93ca98d3480b4b763c4defb9d05b082b764b1abac7a4dc00f482d6faf09"
          }})).
          to_return(ok_response)

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
          fingerprint: "07d1a93ca98d3480b4b763c4defb9d05b082b764b1abac7a4dc00f482d6faf09",
          sync: false)

        assert_requested request
      end

    end

    context "when passed both an alias and fingerprint" do

      it "passes the alias as the image to download" do

        request = stub_post("/1.0/images").
          with(body: hash_including({source: {
            type: "image",
            mode: "pull",
            server: "https://images.linuxcontainers.org:8443",
            alias: "ubuntu/xenial/amd64"
          }})).
          to_return(ok_response)

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
          alias: "ubuntu/xenial/amd64",
          fingerprint: "07d1a93ca98d3480b4b763c4defb9d05b082b764b1abac7a4dc00f482d6faf09",
          sync: false)

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
          with(body: hash_including({source: {
            type: "image",
            mode: "pull",
            server: "https://images.linuxcontainers.org:8443",
            protocol: "lxd",
            alias: "ubuntu/xenial/amd64"
          }})).
          to_return(ok_response)

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
          alias: "ubuntu/xenial/amd64",
          protocol: "lxd",
          sync: false)

        assert_requested request
      end

      it "accepts simplestreams" do

        request = stub_post("/1.0/images").
          with(body: hash_including({source: {
            type: "image",
            mode: "pull",
            server: "https://images.linuxcontainers.org:8443",
            protocol: "simplestreams",
            alias: "ubuntu/xenial/amd64"
          }})).
          to_return(ok_response)

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
          alias: "ubuntu/xenial/amd64",
          protocol: "simplestreams",
          sync: false)

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
          with(body: hash_including({source: {
            type: "image",
            mode: "pull",
            server: "https://images.linuxcontainers.org:8443",
            secret: "reallysecret",
            alias: "ubuntu/xenial/amd64",
          }})).
          to_return(ok_response)

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
          alias: "ubuntu/xenial/amd64",
          secret: "reallysecret",
          sync: false)

        assert_requested request

      end

    end

    context "when passed a certificate" do

      it "passes the certificate to the server" do

        request = stub_post("/1.0/images").
          with(body: hash_including({source: {
            type: "image",
            mode: "pull",
            server: "https://images.linuxcontainers.org:8443",
            certificate: test_cert,
            alias: "ubuntu/xenial/amd64",
          }})).
          to_return(ok_response)

        client.create_image_from_remote("https://images.linuxcontainers.org:8443",
          alias: "ubuntu/xenial/amd64",
          certificate: test_cert,
          sync: false)

        assert_requested request

      end

    end

    context "when 'auto_update': true is passed" do

      it "auto-updates the image", :remote_image, :image, :skip_create do

        response = client.create_image_from_remote(
          "https://192.168.103.102:8443",
          alias: "busybox/default",
          certificate: @remote_cert,
          public: true,
          auto_update: true)

        @fingerprint = response.metadata.fingerprint
        image = client.image(@fingerprint)

        expect(image.auto_update).to be_truthy

      end

    end

    context "when auto_update: true is not passed" do

      it "defaults to a non-auto-updated image", :remote_image, :image, :skip_create do

        response = client.create_image_from_remote(
          "https://192.168.103.102:8443",
          alias: "busybox/default",
          certificate: @remote_cert,
          public: true)

        @fingerprint = response.metadata.fingerprint
        image = client.image(@fingerprint)

        expect(image.auto_update).to be_falsy

      end

    end

  end

  describe ".create_image_from_url", :vcr do

    it_behaves_like "an asynchronous operation" do

      after(:each) do
        delete_test_image
      end

      let(:operation) do
        lambda { |options| client.create_image_from_url("http://192.168.103.102", options) }
      end

    end

    it "creates an image", :image, :skip_create do
      response = client.create_image_from_url("http://192.168.103.102")

      @fingerprint = response.metadata.fingerprint
      image = client.image(@fingerprint)

      expect(image.architecture).to eq("x86_64")
      expect(image.public).to eq(false)
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/images").
        with(body: hash_including({source: {
            type: "url",
            url: "http://192.168.103.102/busybox"
          }})).
          to_return(ok_response)
      client.create_image_from_url("http://192.168.103.102/busybox", sync: false)
      assert_requested request
    end

    context "when properties are passed" do

      it "stores them with the image", :image, :skip_create do

        response = client.create_image_from_url(
          "http://192.168.103.102",
          properties: { hello: "world %!@# how are you?!", test: 123 }
        )

        @fingerprint = response.metadata.fingerprint
        image = client.image(@fingerprint)

        expect(image.properties.hello).to eq("world %!@# how are you?!")
        expect(image.properties.test).to eq("123")
      end

    end

    context "when 'public': true is passed" do

      it "makes the image public", :image, :skip_create do
        response = client.create_image_from_url(
          "http://192.168.103.102",
          public: true
        )

        @fingerprint = response.metadata.fingerprint
        image = client.image(@fingerprint)

        expect(image.public).to be_truthy
      end

    end

    context "when public: true is not passed" do

      it "defaults to a private image", :image, :skip_create do
        response = client.create_image_from_url("http://192.168.103.102")
        @fingerprint = response.metadata.fingerprint

        image = client.image(@fingerprint)
        expect(image.public).to be_falsy
      end

    end

    context "when a filename is passed" do

      it "stores the filename with the imported image", :image, :skip_create do
        response = client.create_image_from_url(
          "http://192.168.103.102",
          filename: "busybox-v1.tar.xz")
        @fingerprint = response.metadata.fingerprint

        image = client.image(@fingerprint)
        expect(image.filename).to eq("busybox-v1.tar.xz")
      end

    end

  end

  describe ".create_image_from_container", :vcr do

    it_behaves_like "an asynchronous operation" do

      before(:each) do
        create_test_container
      end

      after(:each) do
        last_response = client.last_response
        delete_test_image(last_response.data.metadata.metadata.fingerprint)
        delete_test_container
      end

      let(:operation) do
        lambda { |options| client.create_image_from_container("test-container", options) }
      end

    end

    after(:each) do
      client.delete_image(@fingerprint, sync: true) if @fingerprint
    end

    it "creates an image", :container do
      response = client.create_image_from_container("test-container")

      @fingerprint = response.metadata.fingerprint
      image = client.image(@fingerprint)

      expect(image.architecture).to eq("x86_64")
      expect(image.public).to eq(false)
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/images").
        with(body: hash_including({:source => {
            type: "container",
            name: "test-container"
          }})).
          to_return(ok_response)
      client.create_image_from_container("test-container", sync: false)
      assert_requested request
    end

    context "when properties are passed", :container do

      it "stores them with the image" do
        response = client.create_image_from_container(
          "test-container",
          properties: { hello: "world %!@# how are you?!", test: 123 }
        )

        @fingerprint = response.metadata.fingerprint
        image = client.image(@fingerprint)

        expect(image.properties.hello).to eq("world %!@# how are you?!")
        expect(image.properties.test).to eq("123")
      end

    end

    context "when 'public': true is passed" do

      it "makes the image public", :container do
        response = client.create_image_from_container("test-container", public: true)
        @fingerprint = response.metadata.fingerprint

        image = client.image(@fingerprint)
        expect(image.public).to be_truthy
      end

    end

    context "when public: true is not passed" do

      it "defaults to a private image", :container do
        response = client.create_image_from_container("test-container")
        @fingerprint = response.metadata.fingerprint

        image = client.image(@fingerprint)
        expect(image.public).to be_falsy
      end

    end

    context "when a filename is passed" do

      it "stores the filename with the imported image", :container do
        response = client.create_image_from_container("test-container", filename: "busybox-v1.tar.xz")
        @fingerprint = response.metadata.fingerprint

        image = client.image(@fingerprint)
        expect(image.filename).to eq("busybox-v1.tar.xz")
      end

    end

  end

  describe ".create_image_from_snapshot", :vcr do

    it_behaves_like "an asynchronous operation" do

      before(:each) do
        create_test_container
        client.create_snapshot("test-container", "test-snapshot", sync: true)
      end

      after(:each) do
        last_response = client.last_response
        delete_test_image(last_response.data.metadata.metadata.fingerprint)
        delete_test_container
      end

      let(:operation) do
        lambda { |options| client.create_image_from_snapshot("test-container", "test-snapshot", options) }
      end

    end

    after do
      client.delete_image(@fingerprint) if @fingerprint
    end

    it "creates an image", :container, :snapshot do
      response = client.create_image_from_snapshot("test-container", "test-snapshot")
      @fingerprint = response.metadata.fingerprint

      image = client.image(@fingerprint)

      expect(image.architecture).to eq("x86_64")
      expect(image.public).to eq(false)
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/images").
        with(body: hash_including({:source => {
            type: "snapshot",
            name: "test-container/snapshot1"
          }})).
          to_return(ok_response)
      client.create_image_from_snapshot("test-container", "snapshot1", sync: false)
      assert_requested request
    end

    context "when properties are passed" do

      it "stores them with the image", :container, :snapshot do
        response = client.create_image_from_snapshot(
          "test-container",
          "test-snapshot",
          properties: { hello: "world %!@# how are you?!", test: 123 }
        )

        @fingerprint = response.metadata.fingerprint
        image = client.image(@fingerprint)

        expect(image.properties.hello).to eq("world %!@# how are you?!")
        expect(image.properties.test).to eq("123")
      end

    end

    context "when 'public': true is passed" do

      it "makes the image public", :container, :snapshot do
        response = client.create_image_from_snapshot(
          "test-container",
          "test-snapshot",
          public: true
        )

        @fingerprint = response.metadata.fingerprint
        image = client.image(@fingerprint)

        expect(image.public).to be_truthy
      end

    end

    context "when public: true is not passed" do

      it "defaults to a private image", :container, :snapshot do
        response = client.create_image_from_snapshot("test-container", "test-snapshot")
        @fingerprint = response.metadata.fingerprint

        image = client.image(@fingerprint)
        expect(image.public).to be_falsy
      end

    end

    context "when a filename is passed" do

      it "stores the filename with the imported image", :container, :snapshot do
        response = client.create_image_from_snapshot(
          "test-container",
          "test-snapshot",
          filename: "busybox-v1.tar.xz"
        )

        @fingerprint = response.metadata.fingerprint
        image = client.image(@fingerprint)

        expect(image.filename).to eq("busybox-v1.tar.xz")
      end

    end

  end

  describe ".delete_image", :vcr do

    it_behaves_like "an asynchronous operation" do

      before(:each) do
        @fingerprint = create_test_image
      end

      let(:operation) do
        lambda { |options| client.delete_image(@fingerprint, options) }
      end

    end

    it "deletes an existing image", :image, :skip_delete do
      expect(client.images).to include(@fingerprint)
      client.delete_image(@fingerprint)
      expect(client.images).to_not include(@fingerprint)
    end

    it "makes the correct API call" do
      request = stub_delete("/1.0/images/test").to_return(ok_response)
      client.delete_image("test", sync: false)
      assert_requested request
    end

  end

  describe ".update_image", :vcr do

    it "makes the correct API call" do
      request = stub_put("/1.0/images/test").
        with(body: hash_including({
          public: true,
          properties: { hello: "world" }
        })).
        to_return(ok_response)

      client.update_image("test", public: true, properties: { hello: "world" })
      assert_requested request
    end

    context "when properties are passed" do

      it "stores them with the image", :image do
        image = client.image(@fingerprint)

        properties = image.properties.to_hash.merge({
          hello: "world",
          test: 123
        })

        client.update_image(@fingerprint, properties: properties)
        image = client.image(@fingerprint)

        expect(image.properties.hello).to eq("world")
        expect(image.properties.test).to eq("123")
        expect(image.properties.description).to eq("Busybox x86_64")
      end

      it "overwrites the existing properties", :image do
        image = client.image(@fingerprint)
        expect(image.properties.description).to eq("Busybox x86_64")

        client.update_image(@fingerprint, properties: {
          hello: "world",
          test: 123
        })

        image = client.image(@fingerprint)

        expect(image.properties.hello).to eq("world")
        expect(image.properties.test).to eq("123")
        expect(image.properties.description).to be_nil
      end

    end

    context "when 'public': true is passed" do

      it "makes the image public", :image do
        image = client.image(@fingerprint)
        expect(image.public).to be_falsy

        client.update_image(@fingerprint, public: true)

        image = client.image(@fingerprint)
        expect(image.public).to be_truthy
      end

    end

    context "when public: false is passed" do

      it "makes the image private", :image, :public do
        image = client.image(@fingerprint)
        expect(image.public).to be_truthy

        client.update_image(@fingerprint, public: false)

        image = client.image(@fingerprint)
        expect(image.public).to be_falsy
      end

    end

    context "when 'auto_update': true is passed" do

      it "sets the image to auto-update", :image do
        image = client.image(@fingerprint)
        expect(image.auto_update).to be_falsy

        client.update_image(@fingerprint, auto_update: true)
        image = client.image(@fingerprint)

        expect(image.auto_update).to be_truthy
      end

    end

    context "when 'auto_update': false is passed" do

      it "disables auto-updating", :remote_image, :image, :skip_create do
        response = client.create_image_from_remote(
          "https://192.168.103.102:8443",
          alias: "busybox/default",
          certificate: @remote_cert,
          auto_update: true)

        @fingerprint = response.metadata.fingerprint
        image = client.image(@fingerprint)

        expect(image.auto_update).to be_truthy

        client.update_image(@fingerprint, auto_update: false)
        image = client.image(@fingerprint)

        expect(image.auto_update).to be_falsy
      end

    end

  end

  describe ".create_image_secret", :vcr do

    it "creates a secret for an image", :image do
      secret = client.create_image_secret(@fingerprint).metadata.secret
      expect { unauthenticated_client.image(@fingerprint) }.to raise_error(Hyperkit::NotFound)

      image = unauthenticated_client.image(@fingerprint, secret: secret)
      expect(image.fingerprint).to eq(@fingerprint)
    end

    it "accepts a prefix of an image fingerprint", :image do
      secret = client.create_image_secret(@fingerprint[0..2]).metadata.secret
      expect { unauthenticated_client.image(@fingerprint) }.to raise_error(Hyperkit::NotFound)

      image = unauthenticated_client.image(@fingerprint[0..2], secret: secret)
      expect(image.fingerprint).to eq(@fingerprint)
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/images/test/secret").
        to_return(ok_response)

      client.create_image_secret("test")
      assert_requested request
    end

  end

  describe ".export_image", :vcr do

    it "exports an image to a file", :image do

      Dir.mktmpdir("hyperkit") do |dir|
        output_file = client.export_image(@fingerprint, dir)
        checksum = Digest::SHA256.hexdigest(File.read(output_file))
        expect(checksum).to eq(@fingerprint)
      end

    end

    it "returns the full path to the exported file", :image do
      image = client.image(@fingerprint)

      Dir.mktmpdir("hyperkit") do |dir|
        output_file = client.export_image(@fingerprint, dir)
        expect(output_file).to eq(File.join(dir, image.filename))
      end

    end

    it "allows the filename to be overridden", :image do
      image = client.image(@fingerprint)

      Dir.mktmpdir("hyperkit") do |dir|
        output_file = client.export_image(@fingerprint, dir, filename: "test.tar.xz")
        expect(output_file).to eq(File.join(dir, "test.tar.xz"))
      end

    end

    it "makes the correct API calls" do
      request1 = stub_get("/1.0/images/test").
        to_return(ok_response.merge(body: { metadata: { filename: "test.tar.xz" }}.to_json))

      request2 = stub_get("/1.0/images/test/export").to_return(ok_response)

      Dir.mktmpdir("hyperkit") do |dir|
        client.export_image("test", dir)
      end

      assert_requested request1
      assert_requested request2
    end

    it "accepts a secret" do
      request1 = stub_get("/1.0/images/test").
        to_return(ok_response.merge(body: { metadata: { filename: "test.tar.xz" }}.to_json))

      request2 = stub_get("/1.0/images/test/export?secret=really-secret").
        to_return(ok_response)

      Dir.mktmpdir("hyperkit") do |dir|
        client.export_image("test", dir, secret: "really-secret")
      end

      assert_requested request1
      assert_requested request2
    end

  end

end
