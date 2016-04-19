require 'spec_helper'

describe Hyperkit::Client::Certificates do

  let(:client) { lxd }

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
      ]}

      stub_get("/1.0/certificates").
        to_return(ok_response.merge(body: body.to_json))

      certs = client.certificates
      expect(certs).to eq(%w[
        3ee64be3c3c7d617a7470e14f2d847081ad467c8c26e1caad841c8f67f7c7b09
        e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
      ])
    end

  end

  describe ".create_certificate", :vcr do

    it "creates a certificate" do
      client.create_certificate(test_cert)
      expect(client.certificates).to include(test_cert_fingerprint)
      client.delete_certificate(test_cert_fingerprint)
    end

    # Note: this is documented in the API, but currently seems to have no effect
    it "allows an optional name to be specified" do
      client.create_certificate(test_cert, {
        name: "qweqwe"
      })
      expect(client.certificates).to include(test_cert_fingerprint)
      client.delete_certificate(test_cert_fingerprint)
    end

    it "passes on a specified trust password for unauthenticated addition of a certificate" do
      request = stub_post("/1.0/certificates").
          with(body: hash_including({ password: "server-trust-password" })).
        to_return(ok_response)

      unauthenticated_client.create_certificate(test_cert, {
        password: "server-trust-password"
      })

      assert_requested request
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/certificates").to_return(ok_response)
      client.create_certificate(test_cert)
      assert_requested request
    end


  end

  describe ".certificate", :vcr do

    it "retrieves a certificate" do
      client.create_certificate(test_cert)
      cert = client.certificate(test_cert_fingerprint)

      expect(cert.certificate).to eq(test_cert)
      expect(cert.fingerprint).to eq(test_cert_fingerprint)
      expect(cert.type).to eq("client")

      client.delete_certificate(test_cert_fingerprint)
    end

    it "accepts a prefix of a certificate fingerprint" do
      client.create_certificate(test_cert)
      cert = client.certificate(test_cert_fingerprint[0..2])

      expect(cert.certificate).to eq(test_cert)
      expect(cert.fingerprint).to eq(test_cert_fingerprint)
      expect(cert.type).to eq("client")

      client.delete_certificate(test_cert_fingerprint)
    end

    it "makes the correct API call" do
      request = stub_get("/1.0/certificates/#{test_cert_fingerprint}").
        to_return(ok_response)

      client.certificate(test_cert_fingerprint)
      assert_requested request
    end

  end

  describe ".delete_certificate", :vcr do

    it "deletes an existing certificate" do
      client.create_certificate(test_cert)
      client.delete_certificate(test_cert_fingerprint)
      expect(client.certificates).to_not include(test_cert_fingerprint)
    end

    it "accepts a prefix of a certificate fingerprint" do
      client.create_certificate(test_cert)
      client.delete_certificate(test_cert_fingerprint[0..2])
      expect(client.certificates).to_not include(test_cert_fingerprint)
    end

    it "makes the correct API call" do
      request = stub_delete("/1.0/certificates/#{test_cert_fingerprint}").
        to_return(ok_response)
      client.delete_certificate(test_cert_fingerprint)
      assert_requested request
    end

  end

end
