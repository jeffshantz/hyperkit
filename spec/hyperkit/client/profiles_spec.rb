require 'spec_helper'

describe Hyperkit::Client::Profiles do

  let(:client) { lxd }

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
      ]}

      stub_get("/1.0/profiles").
        to_return(ok_response.merge(body: body.to_json))

      profiles = client.profiles
      expect(profiles).to eq(%w[test1 test2 test3])
    end

  end

  describe ".create_profile", :vcr do

    it "creates a profile", :profile, :skip_create do
      client.create_profile("test-profile")
      expect(client.profiles).to include("test-profile")
    end

    it "accepts a config hash", :profile, :skip_create do
      client.create_profile("test-profile", config: {
        "limits.memory" => "2GB"
      })
      profile = client.profile("test-profile")
      expect(profile.config["limits.memory"]).to eq("2GB")
    end

    it "accepts non-String config values", :profile, :skip_create do
      client.create_profile("test-profile", config: {
        "limits.cpu" => 2
      })
      profile = client.profile("test-profile")
      expect(profile.config["limits.cpu"]).to eq("2")
    end

    it "accepts a device hash", :profile, :skip_create do
      client.create_profile("test-profile", devices: {
        "kvm": {
          "type": "unix-char",
          "path": "/dev/kvm"
        }
      })

      profile = client.profile("test-profile")

      expect(profile.devices.kvm.path).to eq("/dev/kvm")
      expect(profile.devices.kvm.type).to eq("unix-char")
    end

    it "accepts a description", :profile, :skip_create do
      client.create_profile("test-profile", description: "hello")
      profile = client.profile("test-profile")
      expect(profile.description).to eq("hello")
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/profiles").to_return(ok_response)
      client.create_profile("test-profile")
      assert_requested request
    end

  end

  describe ".profile", :vcr do

    @profile_data = {
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

    it "retrieves a profile", :profile, profile_options: @profile_data do
      profile = client.profile("test-profile")

      expect(profile.name).to eq("test-profile")
      expect(profile.config[:"raw.lxc"]).to eq("lxc.aa_profile = unconfined")
      expect(profile.description).to eq("A test profile")
      expect(profile.devices.eth0.nictype).to eq("bridged")
      expect(profile.devices.eth0.parent).to eq("br-ext")
      expect(profile.devices.eth0.type).to eq("nic")
    end

    it "makes the correct API call" do
      request = stub_get("/1.0/profiles/test").to_return(ok_response)
      client.profile("test")
      assert_requested request
    end

  end

  describe ".update_profile", :vcr do

    @profile_data = {
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

    it "updates an existing profile", :profile, profile_options: @profile_data do
      client.update_profile("test-profile", {
        config: {},
        description: "An excellent profile",
        devices: {
          eth0: {
            nictype: "bridged",
            parent: "br-int",
            type: "nic"
          }
        }
      })

      profile = client.profile("test-profile")

      expect(profile.name).to eq("test-profile")
      expect(profile.config.to_hash).to be_empty
      expect(profile.description).to eq("An excellent profile")
      expect(profile.devices.eth0.nictype).to eq("bridged")
      expect(profile.devices.eth0.parent).to eq("br-int")
      expect(profile.devices.eth0.type).to eq("nic")
    end

    it "accepts non-String config values", :profile, profile_options: @profile_data do
      client.update_profile("test-profile", config: {
        "limits.cpu" => 2
      })
      profile = client.profile("test-profile")
      expect(profile.config["limits.cpu"]).to eq("2")
    end

    it "makes the correct API call" do
      request = stub_put("/1.0/profiles/test").to_return(ok_response)
      client.update_profile("test")
      assert_requested request
    end

  end

  describe ".rename_profile", :vcr do

    it "renames an existing profile", :profile do
      @profile_name = "test-profile2"
      client.rename_profile("test-profile", @profile_name)
      expect(client.profiles).to include(@profile_name)
      expect(client.profiles).to_not include("test-profile")
      client.delete_profile("test-rename-profile2")
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/profiles/test").
        with(body: hash_including({ name: "test2" })).
        to_return(ok_response)

      client.rename_profile("test", "test2")
      assert_requested request
    end

  end

  describe ".delete_profile", :vcr do

    it "deletes an existing profile", :profile, :skip_delete do
      client.delete_profile("test-profile")
      expect(client.profiles).to_not include("test-profile")
    end

    it "makes the correct API call" do
      request = stub_delete("/1.0/profiles/test").to_return(ok_response)
      client.delete_profile("test")
      assert_requested request
    end

  end

end
