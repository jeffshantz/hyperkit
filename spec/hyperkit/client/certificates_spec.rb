require 'spec_helper'

describe Hyperkit::Client::Certificates do

  let(:client) { Hyperkit::Client.new }

  describe ".certificates", :vcr do

    it "returns an array of certificates" do
      certs = client.certificates
      expect(certs).to be_kind_of(Array)
    end

    it "makes the correct API call" do
      certs = client.certificates
      assert_requested :get, lxd_url("/1.0/certificates")
    end

    it "returns only the certificate hashes and not their paths" do
      body = { metadata: [
        "/1.0/certificates/3ee64be3c3c7d617a7470e14f2d847081ad467c8c26e1caad841c8f67f7c7b09",
        "/1.0/certificates/e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
			]}.to_json
      stub_get("/1.0/certificates").
        to_return(:status => 200, body: body, :headers => {'Content-Type' => 'application/json'})

      certs = client.certificates
      expect(certs).to eq(%w[
        3ee64be3c3c7d617a7470e14f2d847081ad467c8c26e1caad841c8f67f7c7b09
        e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
      ])
    end

  end

  describe ".create_certificate", :vcr do

    it "creates a certificate" do
      client.create_certificate(test_certificate)
			expect(client.certificates).to include(test_certificate_fingerprint)
      client.delete_certificate(test_certificate_fingerprint)
    end

    # Note: this is documented in the API, but currently seems to have no effect
    it "allows an optional name to be specified" do
      client.create_certificate(test_certificate, {
        name: "qweqwe"
      })
			expect(client.certificates).to include(test_certificate_fingerprint)
      client.delete_certificate(test_certificate_fingerprint)
    end

    it "accepts a trust password when unauthenticated" do
      unauthenticated_client.create_certificate(test_certificate, {
        password: "server-trust-password"
      })
			expect(client.certificates).to include(test_certificate_fingerprint)
      client.delete_certificate(test_certificate_fingerprint)
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/certificates").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      client.create_certificate(test_certificate)
      assert_requested request
    end


  end

  describe ".certificate", :vcr do

    it "retrieves a certificate" do
      client.create_certificate(test_certificate)
      cert = client.certificate(test_certificate_fingerprint)

      expect(cert[:certificate]).to eq(test_certificate)
      expect(cert[:fingerprint]).to eq(test_certificate_fingerprint)
      expect(cert[:type]).to eq("client")

      client.delete_certificate(test_certificate_fingerprint)
    end

    it "makes the correct API call" do
			request = stub_get("/1.0/certificates/#{test_certificate_fingerprint}").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.certificate(test_certificate_fingerprint)
      assert_requested request
    end

  end

  describe ".delete_certificate", :vcr do

    it "deletes an existing certificate" do
      client.create_certificate(test_certificate)
      client.delete_certificate(test_certificate_fingerprint)
      expect(client.certificates).to_not include(test_certificate_fingerprint)
    end

    it "makes the correct API call" do
      request = stub_delete("/1.0/certificates/#{test_certificate_fingerprint}").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      client.delete_certificate(test_certificate_fingerprint)
      assert_requested request
    end

  end

end
