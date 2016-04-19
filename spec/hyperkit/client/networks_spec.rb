require 'spec_helper'

describe Hyperkit::Client::Networks do

  let(:client) { lxd }

  describe ".networks", :vcr do

    it "returns an array of networks" do
      networks = client.networks
      expect(networks).to be_kind_of(Array)
    end

    it "makes the correct API call" do
      networks = client.networks
      assert_requested :get, lxd_url("/1.0/networks")
    end

    it "returns only the network names and not their paths" do

      body = { metadata: [
        "/1.0/networks/eth0",
        "/1.0/networks/br-ext"
      ]}

      stub_get("/1.0/networks").
        to_return(ok_response.merge(body: body.to_json))

      networks = client.networks
      expect(networks).to eq(%w[eth0 br-ext])
    end

  end

  describe ".network", :vcr do

    it "retrieves a network" do
      network = client.network("lo")

      expect(network.name).to eq("lo")
      expect(network.type).to eq("loopback")
      expect(network.used_by).to eq([])
    end

    it "makes the correct API call" do
      request = stub_get("/1.0/networks/lo").
        to_return(ok_response)

      client.network("lo")
      assert_requested request
    end

  end

end

