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

end
