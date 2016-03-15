require 'spec_helper'

describe Hyperkit::Client::Operations do

  let(:client) { Hyperkit::Client.new }

  describe ".operations", :vcr do

    it "returns an array of operations" do
      operations = client.operations
      expect(operations).to be_kind_of(Array)
    end

    it "returns a flat array of operations" do
      body = { metadata: {
        running: [
          "/1.0/operations/18b45cfd-30e4-43b3-8f28-91d00701cdb3",
          "/1.0/operations/ec271d63-c43a-4c21-8cd7-d6899333b3f0"
        ]
      }}.to_json

      stub_get("/1.0/operations").
        to_return(:status => 200, body: body, :headers => {'Content-Type' => 'application/json'})

      operations = client.operations
      expect(operations).to eq(%w[
        18b45cfd-30e4-43b3-8f28-91d00701cdb3
        ec271d63-c43a-4c21-8cd7-d6899333b3f0
      ])
    end

    it "makes the correct API call" do
      operations = client.operations
      assert_requested :get, lxd_url("/1.0/operations")
    end

  end

end
