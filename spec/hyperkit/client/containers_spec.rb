require 'spec_helper'

describe Hyperkit::Client::Containers do

  let(:client) { Hyperkit::Client.new }

  describe ".containers", :vcr do

    it "returns an array of containers" do
      containers = client.containers
      expect(containers).to be_kind_of(Array)
    end

    it "makes the correct API call" do
      containers = client.containers
      assert_requested :get, lxd_url("/1.0/containers")
    end

    it "returns only the image names and not their paths" do
      body = { metadata: [
        "/1.0/containers/test1",
        "/1.0/containers/test2",
        "/1.0/containers/test3",
        "/1.0/containers/test4"
			]}.to_json
      stub_get("/1.0/containers").
        to_return(:status => 200, body: body, :headers => {'Content-Type' => 'application/json'})

      containers = client.containers
      expect(containers).to eq(%w[test1 test2 test3 test4])
    end

  end

end
