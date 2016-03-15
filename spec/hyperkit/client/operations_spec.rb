require 'spec_helper'
require 'time'

describe Hyperkit::Client::Operations do

  let(:client) { Hyperkit::Client.new }
  let(:operation) {
    {
      "id": "b8d84888-1dc2-44fd-b386-7f679e171ba5",
      "class": "token",
      "created_at": "2016-02-17T16:59:27.237628195-05:00",
      "updated_at": "2016-02-17T16:59:27.237628195-05:00",
      "status": "Running",
      "status_code": 103,
      "resources": {
          "images": [
              "/1.0/images/54c8caac1f61901ed86c68f24af5f5d3672bdc62c71d04f06df3a59e95684473"
          ]
      },
      "metadata": {
          "secret": "c9209bee6df99315be1660dd215acde4aec89b8e5336039712fc11008d918b0d"
      },
      "may_cancel": true,
      "err": ""
    }
  }
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

  describe ".operation", :vcr do

    it "retrieves an operation" do
      stub_get("/1.0/operations/b8d84888-1dc2-44fd-b386-7f679e171ba5").
        to_return(:status => 200, body: operation.to_json, :headers => {'Content-Type' => 'application/json'})

      op = client.operation("b8d84888-1dc2-44fd-b386-7f679e171ba5")
      expect(op).to eq(operation.merge(created_at: Time.parse(operation[:created_at]), updated_at: Time.parse(operation[:updated_at])))
    end

    it "makes the correct API call" do
      request = stub_get("/1.0/operations/b8d84888-1dc2-44fd-b386-7f679e171ba5").
        to_return(:status => 200, body: operation.to_json, :headers => {'Content-Type' => 'application/json'})

      op = client.operation("b8d84888-1dc2-44fd-b386-7f679e171ba5")
      assert_requested request
    end

  end

end
