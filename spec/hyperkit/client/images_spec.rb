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
			fingerprint = "45bcc353f629b23ce30ef4cca14d2a4990c396d85ea68905795cc7579c145123"
      client.api_endpoint = 'https://images.linuxcontainers.org:8443'
      image = client.image(fingerprint)

			expect(image[:properties][:description]).to include("Centos 6 (amd64)")
			expect(image[:architecture]).to eq("x86_64")
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

end

