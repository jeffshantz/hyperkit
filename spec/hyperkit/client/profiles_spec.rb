require 'spec_helper'

describe Hyperkit::Client::Profiles do

  let(:client) { Hyperkit::Client.new }
  let(:profile_data) {
    {
      description: "A test profile",
      config: {
        "raw.lxc" => "lxc.aa_profile = unconfined"
      },
      devices: {
        eth0: {
          nictype: "bridged",
          parent: "br-ext",
          type: "nic"
        }
			}
		}
  }

  describe ".profiles", :vcr do

    it "returns an array of profiles" do
      profiles = client.profiles
      expect(profiles).to be_kind_of(Array)
    end

    it "makes the correct API call" do
      profiles = client.profiles
      assert_requested :get, lxd_url("/1.0/profiles")
    end

    it "returns only the profile names and not their paths" do
      body = { metadata: [
				"/1.0/profiles/test1",
        "/1.0/profiles/test2",
        "/1.0/profiles/test3"
			]}.to_json
      stub_get("/1.0/profiles").
        to_return(:status => 200, body: body, :headers => {'Content-Type' => 'application/json'})

      profiles = client.profiles
      expect(profiles).to eq(%w[test1 test2 test3])
    end

  end

  describe ".create_profile", :vcr do

    it "creates a profile" do
      client.create_profile("test-create-profile", {})
      expect(client.profiles).to include("test-create-profile")
      client.delete_profile("test-create-profile")
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/profiles").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      client.create_profile("test-profile")
      assert_requested request
    end

  end

  describe ".profile", :vcr do

    it "retrieves a profile" do
      client.create_profile("test-retrieve-profile", profile_data)
      profile = client.profile("test-retrieve-profile")

      expect(profile[:name]).to eq("test-retrieve-profile")
      expect(profile[:config][:"raw.lxc"]).to eq("lxc.aa_profile = unconfined")
      expect(profile[:description]).to eq("A test profile")
      expect(profile[:devices][:eth0][:nictype]).to eq("bridged")
      expect(profile[:devices][:eth0][:parent]).to eq("br-ext")
      expect(profile[:devices][:eth0][:type]).to eq("nic")

      client.delete_profile("test-retrieve-profile")
    end

    it "makes the correct API call" do
			request = stub_get("/1.0/profiles/test").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.profile("test")
      assert_requested request
    end

  end

  describe ".update_profile", :vcr do

    it "updates an existing profile" do
      client.create_profile("test-update-profile", profile_data)
      client.update_profile("test-update-profile", {
        description: "An excellent profile",
        config: { "raw.lxc" => "lxc.aa_profile = unconfined" },
        devices: {
          eth0: {
            nictype: "bridged",
            parent: "br-int",
            type: "nic"
          }
        }
      })
      profile = client.profile("test-update-profile")

      expect(profile[:name]).to eq("test-update-profile")
      expect(profile[:config][:"raw.lxc"]).to eq("lxc.aa_profile = unconfined")
      expect(profile[:description]).to eq("An excellent profile")
      expect(profile[:devices][:eth0][:nictype]).to eq("bridged")
      expect(profile[:devices][:eth0][:parent]).to eq("br-int")
      expect(profile[:devices][:eth0][:type]).to eq("nic")

      client.delete_profile("test-update-profile")

    end

    it "makes the correct API call" do
      request = stub_put("/1.0/profiles/test").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      client.update_profile("test", {})
      assert_requested request
    end

  end

  describe ".rename_profile", :vcr do

    it "renames an existing profile" do
      client.create_profile("test-rename-profile1")
      client.rename_profile("test-rename-profile1", "test-rename-profile2")
      expect(client.profiles).to include("test-rename-profile2")
      expect(client.profiles).to_not include("test-rename-profile1")
      client.delete_profile("test-rename-profile2")
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/profiles/test").
        to_return(status: 200, body: {name: "test2"}.to_json, headers: { 'Content-Type' => 'application/json' })
      client.rename_profile("test", "test2")
      assert_requested request
    end

  end

  describe ".delete_profile", :vcr do

    it "deletes an existing profile" do
      client.create_profile("test-delete-profile")
      client.delete_profile("test-delete-profile")
      expect(client.profiles).to_not include("test-delete-profile")
    end

    it "makes the correct API call" do
      request = stub_delete("/1.0/profiles/test").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      client.delete_profile("test")
      assert_requested request
    end

  end

end
