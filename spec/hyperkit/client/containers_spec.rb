require 'spec_helper'
require 'tempfile'
require 'tmpdir'

describe Hyperkit::Client::Containers do

  let(:client) { lxd }

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
        to_return(ok_response.merge(body: body))

      containers = client.containers
      expect(containers).to eq(%w[test1 test2 test3 test4])
    end

  end

  describe ".container", :vcr do

    it "retrieves a container", :container do
      container = client.container("test-container")
      expect(container.name).to eq("test-container")
      expect(container.architecture).to eq("x86_64")
    end

    it "makes the correct API call" do
      request = stub_get("/1.0/containers/test").to_return(ok_response)
      client.container("test")
      assert_requested request
    end

  end

  describe ".container_state", :vcr do

    it "returns the current state of a container", :container do
      state = client.container_state("test-container")
      expect(state.status).to eq("Stopped")
    end

    it "makes the correct API call" do
      request = stub_get("/1.0/containers/test/state").to_return(ok_response)
      client.container_state("test")
      assert_requested request
    end

  end

  describe ".create_container", :vcr, :skip_create do

    it_behaves_like "an asynchronous operation" do

      after { delete_test_container }

      let(:operation) do
        lambda { |options| client.create_container("test-container", { alias: "cirros" }.merge(options)) }
      end

    end

    it "creates a container in the 'Stopped' state", :container do
      client.create_container("test-container", alias: "cirros")
      container = client.container("test-container")
      expect(container.status).to eq("Stopped")
    end

    it "passes on the container name" do
      request = stub_post("/1.0/containers").
        with(body: hash_including({
          name: "test-container",
          source: { type: "image", alias: "busybox" }
        })).
        to_return(ok_response)

      client.create_container("test-container", alias: "busybox", sync: false)
      assert_requested request
    end

    context "when an architecture is specified" do

      it "passes on the architecture" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test-container",
            architecture: "x86_64",
            source: { type: "image", alias: "busybox" }
          })).
          to_return(ok_response)

        client.create_container("test-container",
          alias: "busybox",
          architecture: "x86_64",
          sync: false)

        assert_requested request
      end

    end

    context "when a list of profiles is specified" do

      it "passes on the profiles" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test-container",
            profiles: ['test1', 'test2'],
            source: { type: "image", alias: "busybox" }
          })).
          to_return(ok_response)

        client.create_container("test-container",
          alias: "busybox",
          profiles: ['test1', 'test2'],
          sync: false)

        assert_requested request
      end

      it "applies the profiles to the newly-created container", :container, :profiles do

        create_test_container("test-container",
          empty: true,
          profiles: %w[test-profile1 test-profile2])

        container = client.container("test-container")
        expect(container.profiles).to eq(%w[test-profile1 test-profile2])
      end

    end

    context "when 'ephemeral: true' is specified" do

      it "passes it along" do

        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test-container",
            ephemeral: true,
            source: { type: "image", alias: "busybox" }
          })).
          to_return(ok_response)

        client.create_container("test-container",
          alias: "busybox",
          ephemeral: true,
          sync: false)

        assert_requested request
      end

      it "makes the container ephemeral", :container do
        create_test_container("test-container", ephemeral: true, empty: true)
        container = client.container("test-container")
        expect(container).to be_ephemeral
      end

    end

    context "when 'ephemeral: true' is not specified" do

      it "defaults to a persistent container", :container do
        create_test_container("test-container", empty: true)
        container = client.container("test-container")
        expect(container).to_not be_ephemeral
      end

    end

    context "when a config hash is specified" do

      it "passes on the configuration" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
              name: "test-container",
              config: { hello: "world" },
              source: { type: "image", alias: "busybox" }
          })).
          to_return(ok_response)

        client.create_container("test-container",
          alias: "busybox",
          config: { hello: "world" },
          sync: false)

        assert_requested request
      end

      it "stores the configuration with the container", :container do

        create_test_container("test-container",
          config: { "volatile.eth0.hwaddr" => "aa:bb:cc:dd:ee:ff" },
          empty: true)

        container = client.container("test-container")
        expect(container.config["volatile.eth0.hwaddr"]).to eq("aa:bb:cc:dd:ee:ff")
      end

      it "accepts non-String values", :container do

        create_test_container("test-container",
          config: { "limits.cpu" => 2 },
          empty: true)

        container = client.container("test-container")
        expect(container.config["limits.cpu"]).to eq("2")
      end

    end

    context "when an image is specified by alias" do

      it "passes on the alias" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test-container",
            source: { type: "image", alias: "busybox" }
          })).
          to_return(ok_response)

        client.create_container("test-container", alias: "busybox", sync: false)
        assert_requested request
      end

      it "creates a container by image alias", :container do
        create_test_container("test-container", alias: "cirros")
        container = client.container("test-container")

        image_alias = client.image_alias("cirros")
        expect(container.config["volatile.base_image"]).to eq(image_alias.target)
      end

    end

    context "when an image is specified by fingerprint" do

      it "passes on the fingerprint" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test-container",
            source: { type: "image", fingerprint: "test-fingerprint" }
          })).
          to_return(ok_response)

        client.create_container("test-container",
          fingerprint: "test-fingerprint",
          sync: false)

        assert_requested request
      end

      it "creates a container by image fingerprint", :container do
        fingerprint = client.image_by_alias("cirros").fingerprint
        client.create_container("test-container", fingerprint: fingerprint)

        container = client.container("test-container")
        expect(container.config["volatile.base_image"]).to eq(fingerprint)
      end

    end

    context "when 'empty: true' is specified" do

      it "passes the source type as 'none'" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test-container",
            source: { type: "none" }
          })).
          to_return(ok_response)

        client.create_container("test-container", empty: true, sync: false)
        assert_requested request
      end

      it "creates an empty container", :container do
        client.create_container("test-container",
          empty: true,
          config: { "volatile.eth0.hwaddr" => "aa:bb:cc:dd:ee:ff" }
        )

        container = client.container("test-container")
        expect(container.config["volatile.base_image"]).to be_nil
        expect(container.config["volatile.eth0.hwaddr"]).to eq("aa:bb:cc:dd:ee:ff")
      end

      [:alias, :certificate, :fingerprint, :properties, :protocol, :secret,:server].each do |prop|

        context "and the :#{prop} key is specified" do

          it "raises an error" do

            call = lambda do
               client.create_container("test-container",
                empty: true,
                prop => "test"
              )
            end

            expect(call).to raise_error(Hyperkit::InvalidImageAttributes)

          end

        end

      end

    end

    context "when an image is specified by properties" do

      it "passes on the properties" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test-container",
            source: { type: "image", properties: { os: "busybox" } }
          })).
          to_return(ok_response)

        client.create_container("test-container",
          properties: { os: "busybox" },
          sync: false)

        assert_requested request
      end

      it "creates a container by image properties", :container do
        client.create_container("test-container",
          properties: { os: "Cirros", architecture: "x86_64" })

        container = client.container("test-container")
        fingerprint = client.image_by_alias("cirros").fingerprint
        expect(container.config["volatile.base_image"]).to eq(fingerprint)
      end

    end

    context "when no alias, fingerprint, properties, or empty: true are specified" do

      it "raises an error" do
        call = lambda { client.create_container("test-container") }
        expect(call).to raise_error(Hyperkit::ImageIdentifierRequired)
      end

    end

    context "when a fingerprint and alias are specified" do

      it "passes on the fingerprint" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test-container",
            source: { type: "image", fingerprint: "test-fingerprint" }
          })).
          to_return(ok_response)

        client.create_container("test-container",
          alias: "test-alias",
          fingerprint: "test-fingerprint",
          sync: false)

        assert_requested request
      end

    end

    context "when a fingerprint and properties are specified" do

      it "passes on the fingerprint" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test-container",
            source: { type: "image", fingerprint: "test-fingerprint" }
          })).
          to_return(ok_response)

        client.create_container("test-container",
          fingerprint: "test-fingerprint",
          properties: { hello: "world" },
          sync: false)

        assert_requested request
      end

    end

    context "when an alias and properties are specified" do

      it "passes on the alias" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test-container",
            source: { type: "image", alias: "test-alias" }
          })).
          to_return(ok_response)

        client.create_container("test-container",
          alias: "test-alias",
          properties: { hello: "world" },
          sync: false)

        assert_requested request
      end

    end

    context "when no server is specified" do

      it "does not pass a mode" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test-container",
            source: { type: "image", alias: "test-alias" }
          })).
          to_return(ok_response)

        client.create_container("test-container", alias: "test-alias", sync: false)
        assert_requested request
      end

      [:protocol, :certificate, :secret].each do |prop|

        context "when the #{prop} option is passed" do

          it "raises an error" do

            call = lambda do
              client.create_container("test-container",
                alias: "test-alias",
                prop => "test")
            end

            expect(call).to raise_error(Hyperkit::InvalidImageAttributes)
          end

        end

      end

    end

    context "when a server is specified" do

      it "sets the mode to pull" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test-container",
            source: {
              type: "image",
              mode: "pull",
              server: "test-server",
              alias: "test-alias"
            }
          })).
          to_return(ok_response)

        client.create_container("test-container",
          alias: "test-alias",
          server: "test-server",
          sync: false)

        assert_requested request
      end

      it "creates the container from a remote image", :container, :delete_image do
        image_alias = remote_lxd.image_alias("ubuntu/xenial/amd64")

        client.create_container("test-container",
          server: "https://images.linuxcontainers.org:8443",
          alias: "ubuntu/xenial/amd64")

        container = client.container("test-container")
        expect(container.config["volatile.base_image"]).to eq(image_alias.target)
      end

      context "when passed a protocol" do

        it "accepts lxd" do
          request = stub_post("/1.0/containers").
            with(body: hash_including({source: {
              type: "image",
              mode: "pull",
              server: "https://images.linuxcontainers.org:8443",
              protocol: "lxd",
              alias: "ubuntu/xenial/amd64",
            }})).
            to_return(ok_response)

          client.create_container("test-container",
            server: "https://images.linuxcontainers.org:8443",
            alias: "ubuntu/xenial/amd64",
            protocol: "lxd",
            sync: false)

          assert_requested request
        end

        it "accepts simplestreams" do
          request = stub_post("/1.0/containers").
            with(body: hash_including({source: {
              type: "image",
              mode: "pull",
              server: "https://images.linuxcontainers.org:8443",
              protocol: "simplestreams",
              alias: "ubuntu/xenial/amd64",
            }})).
            to_return(ok_response)

          client.create_container("test-container",
            server: "https://images.linuxcontainers.org:8443",
            alias: "ubuntu/xenial/amd64",
            protocol: "simplestreams",
            sync: false)

          assert_requested request
        end

        it "raises an error on invalid input" do

          call = lambda do
            client.create_container("test-container",
              server: "https://images.linuxcontainers.org:8443",
              alias: "ubuntu/xenial/amd64",
              protocol: "qwe")
          end

          expect(call).to raise_error(Hyperkit::InvalidProtocol)
        end

      end

      context "when passed a secret" do

        it "passes the secret to the server" do
          request = stub_post("/1.0/containers").
            with(body: hash_including({source: {
              type: "image",
              mode: "pull",
              server: "https://images.linuxcontainers.org:8443",
              secret: "reallysecret",
              alias: "ubuntu/xenial/amd64",
            }})).
            to_return(ok_response)

          client.create_container("test-container",
            server: "https://images.linuxcontainers.org:8443",
            alias: "ubuntu/xenial/amd64",
            secret: "reallysecret",
            sync: false)

          assert_requested request
        end

      end

      context "when passed a certificate" do

        it "passes the certificate to the server" do
          request = stub_post("/1.0/containers").
            with(body: hash_including({source: {
              type: "image",
              mode: "pull",
              server: "https://images.linuxcontainers.org:8443",
              certificate: test_cert,
              alias: "ubuntu/xenial/amd64",
            }})).
            to_return(ok_response)

          client.create_container("test-container",
            server: "https://images.linuxcontainers.org:8443",
            alias: "ubuntu/xenial/amd64",
            certificate: test_cert,
            sync: false)

          assert_requested request
        end

      end

    end

  end

  describe ".start_container", :vcr do

    it_behaves_like "an asynchronous operation" do

      before { create_test_container }
      after { delete_test_container }

      let(:operation) do
        lambda do |options|
          client.start_container("test-container", options)
        end

      end

    end

    it "starts a stopped container", :container do
      state = client.container_state("test-container")
      expect(state.status).to eq("Stopped")

      client.start_container("test-container")

      state = client.container_state("test-container")
      expect(state.status).to eq("Running")
    end

    it "accepts a timeout" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "start",
          timeout: 30
        })).
        to_return(ok_response)

      client.start_container("test", timeout: 30, sync: false)
      assert_requested request
    end

    it "allows the operation to be stateful" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "start",
          stateful: true
        })).
        to_return(ok_response)

      client.start_container("test", stateful: true, sync: false)
      assert_requested request
    end

  end

  describe ".stop_container", :vcr do

    it_behaves_like "an asynchronous operation" do

      before do
        create_test_container
        client.start_container("test-container", sync: true)
      end

      after { delete_test_container }

      let(:operation) do
        lambda do |options|
          client.stop_container("test-container", {force: true}.merge(options))
        end

      end

    end

    it "stops a running container", :container, :running do
      state = client.container_state("test-container")
      expect(state.status).to eq("Running")

      client.stop_container("test-container", force: true)

      state = client.container_state("test-container")
      expect(state.status).to eq("Stopped")
    end

    it "throws an error if the container is not running", :container do
      state = client.container_state("test-container")
      expect(state.status).to eq("Stopped")

      call = lambda { client.stop_container("test-container") }
      expect(call).to raise_error(Hyperkit::BadRequest)
    end

    it "accepts a timeout" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "stop",
          timeout: 30
        })).
        to_return(ok_response)

      client.stop_container("test", timeout: 30, sync: false)
      assert_requested request
    end

    it "allows the operation to be forced" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "stop",
          force: true
        })).
        to_return(ok_response)

      client.stop_container("test", force: true, sync: false)
      assert_requested request
    end

    it "allows the operation to be stateful" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "stop",
          stateful: true
        })).
        to_return(ok_response)

      client.stop_container("test", stateful: true, sync: false)
      assert_requested request
    end

  end

  describe ".restart_container", :vcr do

    it_behaves_like "an asynchronous operation" do

      before do
        create_test_container
        client.start_container("test-container", sync: true)
      end

      after { delete_test_container }

      let(:operation) do
        lambda do |options|
          client.restart_container("test-container", {force: true}.merge(options))
        end

      end

    end

    it "restarts a running container", :container, :running do
      state = client.container_state("test-container")
      expect(state.status).to eq("Running")
      pid_before = state.pid

      client.restart_container("test-container", force: true)

      state = client.container_state("test-container")
      expect(state.status).to eq("Running")
      pid_after = state.pid

      expect(pid_after).to_not eq(pid_before)
    end

    it "throws an error if the container is not running", :container do
      state = client.container_state("test-container")
      expect(state.status).to eq("Stopped")

      call = lambda { client.restart_container("test-container") }
      expect(call).to raise_error(Hyperkit::BadRequest)
    end

    it "allows the operation to be forced" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "restart",
          force: true
        })).
        to_return(ok_response)

      client.restart_container("test", force: true, sync: false)
      assert_requested request
    end

    it "accepts a timeout" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "restart",
          timeout: 30
        })).
        to_return(ok_response)

      client.restart_container("test", timeout: 30, sync: false)
      assert_requested request
    end

  end

  describe ".freeze_container", :vcr do

    it_behaves_like "an asynchronous operation" do

      before do
        create_test_container
        client.start_container("test-container", sync: true)
      end

      after { delete_test_container }

      let(:operation) do
        lambda do |options|
          client.freeze_container("test-container", {force: true}.merge(options))
        end

      end

    end

    it "suspends a running container", :container, :running do
      state = client.container_state("test-container")
      expect(state.status).to eq("Running")

      client.freeze_container("test-container")

      state = client.container_state("test-container")
      expect(state.status).to eq("Frozen")
    end

    it "throws an error if the container is not running", :container do
      state = client.container_state("test-container")
      expect(state.status).to eq("Stopped")

      call = lambda { client.freeze_container("test-container") }
      expect(call).to raise_error(Hyperkit::BadRequest)
    end

    it "accepts a timeout" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "freeze",
          timeout: 30
        })).
        to_return(ok_response)

      client.freeze_container("test", timeout: 30, sync: false)
      assert_requested request
    end

  end

  describe ".unfreeze_container", :vcr do

    it_behaves_like "an asynchronous operation" do

      before do
        create_test_container
        client.start_container("test-container", sync: true)
        client.freeze_container("test-container", sync: true)
      end

      after { delete_test_container }

      let(:operation) do
        lambda do |options|
          client.unfreeze_container("test-container", {force: true}.merge(options))
        end

      end

    end

    it "resumes a frozen container", :container, :frozen do
      state = client.container_state("test-container")
      expect(state.status).to eq("Frozen")

      client.unfreeze_container("test-container")

      state = client.container_state("test-container")
      expect(state.status).to eq("Running")
    end

    it "throws an error if the container is not frozen", :container, :running do
      state = client.container_state("test-container")
      expect(state.status).to eq("Running")

      call = lambda { client.unfreeze_container("test-container") }
      expect(call).to raise_error(Hyperkit::BadRequest)
    end

    it "accepts a timeout" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "unfreeze",
          timeout: 30
        })).
        to_return(ok_response)

      client.unfreeze_container("test", timeout: 30, sync: false)
      assert_requested request
    end

  end

  describe ".update_container", :vcr do

    it_behaves_like "an asynchronous operation" do

      after { delete_test_container }

      let(:operation) do
        lambda do |options|
          client.create_container("test-container", alias: "cirros", sync: true)
          container = client.container("test-container")
          client.update_container("test-container", container, options)
        end

      end

    end

    it "updates the configuration of a container", :container, :running do
      container = client.container("test-container")
      expect(container.architecture).to eq("x86_64")
      expect(container.ephemeral).to be_falsy
      expect(container.devices.to_hash.keys).to eq([:root])

      container.architecture = "i686"
      container.devices.eth1 = {nictype: "bridged", parent: "lxcbr0", type: "nic"}

      client.update_container("test-container", container)

      container = client.container("test-container")
      expect(container.architecture).to eq("i686")
      expect(container.devices.to_hash.keys.sort).to eq([:eth1, :root])
      expect(container.devices.eth1.type).to eq("nic")
      expect(container.devices.eth1.parent).to eq("lxcbr0")
      expect(container.devices.eth1.nictype).to eq("bridged")
    end

    it "accepts non-String values", :container do

      container = client.container("test-container").to_hash
      container.merge!(config: container[:config].merge("limits.cpu" => 2))

      client.update_container("test-container", container)

      container = client.container("test-container")
      expect(container.config["limits.cpu"]).to eq("2")
    end

    it "makes the correct API call" do
      request = stub_put("/1.0/containers/test").
        with(body: hash_including({
          hello: "world"
        })).
        to_return(ok_response)

      client.update_container("test", {hello: "world"}, sync: false)
      assert_requested request
    end

  end

  describe ".delete_container", :vcr, :skip_delete do

    it_behaves_like "an asynchronous operation" do

      before { create_test_container }

      let(:operation) do
        lambda do |options|
          client.delete_container("test-container", options)
        end

      end

    end

    it "deletes the container", :container do
      expect(client.containers).to include("test-container")
      client.delete_container("test-container")
      expect(client.containers).to_not include("test-container")
    end

    it "raises an exception if the container is running", :container, :running, skip_delete: false do
      call = lambda { client.delete_container("test-container") }
      expect(call).to raise_error(Hyperkit::BadRequest)
    end

    it "makes the correct API call" do
      request = stub_delete("/1.0/containers/test").to_return(ok_response)
      client.delete_container("test", sync: false)
      assert_requested request
    end

  end

  describe ".rename_container", :vcr do

    it_behaves_like "an asynchronous operation" do

      after { delete_test_container("test-container-2") }

      let(:operation) do
        lambda do |options|
          client.create_container("test-container", alias: "cirros", sync: true)
          client.rename_container("test-container", "test-container-2", options)
        end

      end

    end

    it "renames a container", :container do
      @test_container_name = "test-container-2"

      expect(client.containers).to include("test-container")
      expect(client.containers).to_not include(@test_container_name)

      client.rename_container("test-container", @test_container_name)

      expect(client.containers).to_not include("test-container")
      expect(client.containers).to include(@test_container_name)
    end

    it "fails if the container is running", :container, :running do
      call = lambda { client.rename_container("test-container", "test-container-2") }
      expect(call).to raise_error(Hyperkit::BadRequest)
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/containers/test").
        with(body: hash_including({
          name: "test2"
        })).
        to_return(ok_response)

      client.rename_container("test", "test2", sync: false)
      assert_requested request
    end
  end

  describe ".init_migration", :vcr do

    context "when the source is a container" do

      it "returns secrets used by a target LXD instance to migrate the container", :container do
        response = client.init_migration("test-container")

        expect(response.websocket.url).to_not be_nil
        expect(response.websocket.secrets.control).to_not be_nil
        expect(response.websocket.secrets.fs).to_not be_nil
        expect(response.snapshot).to be_falsy
      end

      it "makes the correct API call" do
        request = stub_post("/1.0/containers/test").
          with(body: hash_including({
            migration: true
          })).
          to_return(ok_response.merge(body: { operation: "", metadata: { metadata: {} } }.to_json))

          stub_get("/1.0/containers/test").to_return(ok_response.merge(body: {
            metadata: {
              architecture: "x86_64",
              config: {}
            }
          }.to_json))

        client.init_migration("test")
        assert_requested request
      end

    end

    context "when the source is a snapshot" do

      it "returns secrets used by a target LXD instance to migrate the snapshot", :container, :snapshot do
        response = client.init_migration("test-container", "test-snapshot")

        expect(response.websocket.url).to_not be_nil
        expect(response.websocket.secrets.control).to_not be_nil
        expect(response.websocket.secrets.fs).to_not be_nil
        expect(response.snapshot).to be_truthy
      end

      it "makes the correct API call" do
        stub_get("/1.0/containers/test/snapshots/snap").to_return(ok_response.merge(body: {
          metadata: {
            architecture: "x86_64",
            config: {}
          }
        }.to_json))

        request = stub_post("/1.0/containers/test/snapshots/snap").
          with(body: hash_including({
            migration: true
          })).
          to_return(ok_response.merge(body: { operation: "", metadata: { metadata: {} } }.to_json))

        client.init_migration("test", "snap")
        assert_requested request
      end

    end

  end

  describe ".migrate", :vcr do

    let(:test_source) { test_migration_source }
    let(:test_snapshot_source) { test_migration_source(test_migration_source_data.merge(snapshot: true)) }

    before(:each, remote_container: true) do |example|
      lxd2.create_container("test-remote", alias: "cirros", sync: true)

      if example.metadata[:remote_snapshot]
        lxd2.create_snapshot("test-remote", "test-remote-snapshot", sync: true)
      end

    end

    before(:each, remote_running: true) do
      lxd2.start_container("test-remote", sync: true)
    end

    after(:each, remote_container: true) do
      lxd2.delete_container("test-remote", sync: true)
    end

    it_behaves_like "an asynchronous operation" do

      before(:each) do
        lxd2.create_container("test-remote", alias: "cirros", sync: true)
        @source = lxd2.init_migration("test-remote")
      end

      after(:each) do
        lxd.delete_container("test-container", sync: true)
        lxd2.delete_container("test-remote", sync: true)
      end

      let(:operation) do
        lambda do |options|
          client.migrate(@source, "test-container", options)
        end

      end

    end

    context "when the source is a container" do

      it "copies the source container to the target instance", :container, :skip_create, :remote_container do

        source = lxd2.init_migration("test-remote")
        expect(client.containers).to_not include("test-container")

        client.migrate(source, "test-container")
        expect(client.containers).to include("test-container")
      end

      it "passes a base-image" do

        allow(client).to receive(:profiles) { %w[default] }
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            "base-image" => "test-base-image"
          })).
          to_return(ok_response.merge(body: { metadata: {} }.to_json))

        client.migrate(test_source, "test2", sync: false)
        assert_requested request

      end

      context "when move: true is specified" do

        it "does not remove volatile attributes" do
          allow(client).to receive(:profiles) { %w[default] }
          request = stub_post("/1.0/containers").
            with(body: hash_including({
              config: {
                :"volatile.base_image"  => "test-base-image",
                :"volatile.eth0.hwaddr" => "test-eth0-hwaddr",
              }
            })).
            to_return(ok_response)

          client.migrate(test_source, "test2", move: true, sync: false)
          assert_requested request
        end

      end

      context "when move: true is not specified" do

        it "removes volatile attributes" do
          allow(client).to receive(:profiles) { %w[default] }
          request = stub_post("/1.0/containers").
            with(body: hash_including({
              config: {}
            })).
            to_return(ok_response)

          client.migrate(test_source, "test2", sync: false)
          assert_requested request
        end

      end

    end

    context "when an architecture is specified" do

      it "passes it to the server" do
        allow(client).to receive(:profiles) { %w[default] }
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            architecture: "custom-arch"
          })).
          to_return(ok_response)

        client.migrate(test_source, "test2", architecture: "custom-arch", sync: false)
        assert_requested request
      end

    end

    context "when no architecture is specified" do

      it "passes the source container's architecture" do
        allow(client).to receive(:profiles) { %w[default] }
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            architecture: "x86_64"
          })).
          to_return(ok_response)

        client.migrate(test_source, "test2", sync: false)
        assert_requested request
      end

    end

    context "when a certificate is specified" do

      it "passes it as the source server's certificate" do
        allow(client).to receive(:profiles) { %w[default] }
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            source: {
              type: "migration",
              mode: "pull",
              operation: "test-ws-url",
              secrets: {
                control: "test-control-secret",
                fs: "test-fs-secret",
                criu: "test-criu-secret"
              },
              certificate: "overridden"
            }
          })).
          to_return(ok_response)

        client.migrate(test_source, "test2", certificate: "overridden", sync: false)
        assert_requested request
      end

    end

    context "when no certificate is specified" do

      it "passes the certificate returned by the source server" do
        allow(client).to receive(:profiles) { %w[default] }
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            source: {
              type: "migration",
              mode: "pull",
              operation: "test-ws-url",
              secrets: {
                control: "test-control-secret",
                fs: "test-fs-secret",
                criu: "test-criu-secret"
              },
              certificate: "test-certificate"
            }
          })).
          to_return(ok_response)

        client.migrate(test_source, "test2", sync: false)
        assert_requested request
      end

    end

    context "when a config hash is specified" do

      it "passes it to the server" do
        allow(client).to receive(:profiles) { %w[default] }
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            config: {
              hello: "world"
            }
          })).
          to_return(ok_response)

        client.migrate(test_source, "test2", config: { hello: "world" }, sync: false)
        assert_requested request
      end

    end

    context "when no config hash is specified" do

      it "copies source container's configuration", :container, :skip_create, :remote_container do

        container = lxd2.container("test-remote")
        container.config = container.config.to_hash.merge("limits.memory" => "256MB")
        lxd2.update_container("test-remote", container)

        source = lxd2.init_migration("test-remote")
        expect(client.containers).to_not include("test-container")

        client.migrate(source, "test-container")
        migrated = client.container("test-container")

        expect(migrated.config["limits.memory"]).to eq("256MB")

      end

    end

    context "when profiles are passed" do

      it "applies them to the migrated container" do
        allow(client).to receive(:profiles) { %w[default] }
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            profiles: %w[test1 test2]
          })).
          to_return(ok_response)

        client.migrate(test_source, "test2", profiles: %w[test1 test2], sync: false)
        assert_requested request
      end

    end

    context "when no profiles are passed" do

      it "applies the profiles from the source container to the migrated container" do

        allow(client).to receive(:profiles) { %w[default] }
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            profiles: %w[default]
          })).
          to_return(ok_response)

        client.migrate(test_source, "test2", sync: false)
        assert_requested request

      end

      context "and not all source profiles exist on the target server" do

        it "raises an error" do
          allow(client).to receive(:profiles) { [] }

          call = lambda { client.migrate(test_source, "test2") }
          expect(call).to raise_error(Hyperkit::MissingProfiles)
        end

      end

    end

    context "when ephemeral: true is specified" do

      it "makes the migrated container ephemeral" do
        allow(client).to receive(:profiles) { %w[default] }
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            ephemeral: true
          })).
          to_return(ok_response)

        client.migrate(test_source, "test2", ephemeral: true, sync: false)
        assert_requested request
      end

    end

    context "when ephemeral: true is not specified" do

      context "and the source container is ephemeral" do

        it "makes the migrated container ephemeral" do

          data = test_migration_source_data.merge(ephemeral: true)
          source = test_migration_source(data)

          allow(client).to receive(:profiles) { %w[default] }
          request = stub_post("/1.0/containers").
            with(body: hash_including({
              ephemeral: true
            })).
            to_return(ok_response)

          client.migrate(source, "test2", sync: false)
          assert_requested request

        end

      end

      context "and the source container is persistent" do

        it "makes the source container persistent" do

          allow(client).to receive(:profiles) { %w[default] }
          request = stub_post("/1.0/containers").
            with(body: hash_including({
              ephemeral: false
            })).
            to_return(ok_response)

          client.migrate(test_source, "test2", sync: false)
          assert_requested request

        end

      end

    end

    context "when the source is a snapshot" do

      it "does not pass a base-image" do

        allow(client).to receive(:profiles) { %w[default] }

        request = stub_post("/1.0/containers").
          with(body: {
            name: "test2",
            architecture: "x86_64",
            source: {
              type: "migration",
              mode: "pull",
              operation: "test-ws-url",
              certificate: "test-certificate",
              secrets: {
                control: "test-control-secret",
                fs: "test-fs-secret",
                criu: "test-criu-secret"
              }
            },
            config: {},
            profiles: ["default"],
            ephemeral: false
          }).
          to_return(ok_response.merge(body: { metadata: {} }.to_json))

        client.migrate(test_snapshot_source, "test2", sync: false)
        assert_requested request

      end

      it "copies the source snapshot to the target instance", :container, :skip_create, :remote_container, :remote_snapshot do

        source = lxd2.init_migration("test-remote", "test-remote-snapshot")
        expect(client.containers).to_not include("test-container")

        client.migrate(source, "test-container")
        expect(client.containers).to include("test-container")
      end

    end

  end

  describe ".copy_container", :vcr do

    it_behaves_like "an asynchronous operation" do

      before(:each) do
        lxd.create_container("test-container", alias: "cirros", sync: true)
      end

      after(:each) do
        lxd.delete_container("test-container", sync: true)
        lxd.delete_container("test-container2", sync: true)
      end

      let(:operation) do
        lambda do |options|
          client.copy_container("test-container", "test-container2", options)
        end

      end

    end

    after(:each, :delete_copy) do
      client.delete_container("test-container2", sync: true)
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/containers").
        with(body: hash_including({
          name: "test2",
          source: { type: "copy", source: "test" }
        })).
        to_return(ok_response.merge(body: { metadata: {} }.to_json))

      client.copy_container("test", "test2", sync: false)
      assert_requested request
    end

    it "copies a stopped container", :container, :delete_copy do
      client.copy_container("test-container", "test-container2")

      container1 = client.container("test-container")
      container2 = client.container("test-container2")

      img1 = container1.config["volatile.base_image"]
      img2 = container2.config["volatile.base_image"]

      expect(img1).to eq(img2)
      expect(container1.architecture).to eq(container2.architecture)
      expect(container1.profiles).to eq(container2.profiles)
    end

    it "copies a running container to a stopped target container", :container, :running, :delete_copy do
      client.copy_container("test-container", "test-container2")

      container1 = client.container("test-container")
      container2 = client.container("test-container2")

      img1 = container1.config["volatile.base_image"]
      img2 = container2.config["volatile.base_image"]

      expect(img1).to eq(img2)
      expect(container1.architecture).to eq(container2.architecture)
      expect(container1.profiles).to eq(container2.profiles)

      expect(container1.status).to eq("Running")
      expect(container2.status).to eq("Stopped")
    end

    it "fails if the target container already exists", :container do
      call = lambda { client.copy_container("test-container", "test-container") }
      expect(call).to raise_error(Hyperkit::BadRequest)
    end

    it "generates new MAC addresses for the target container", :container, :delete_copy do
      client.copy_container("test-container", "test-container2")

      container1 = client.container("test-container")
      container2 = client.container("test-container2")

      mac1 = container1.config["volatile.eth0.hwaddr"]
      mac2 = container2.config["volatile.eth0.hwaddr"]

      expect(mac1).to_not eq(mac2)
    end

    context "when the source container has applied profiles" do

      it "copies the profiles", :container, :profiles, :delete_copy do
        container = client.container("test-container")

        client.update_container("test-container",
          container.to_hash.merge(profiles: %w[test-profile1 test-profile2]))

        client.copy_container("test-container", "test-container2")

        container = client.container("test-container2")
        expect(container.profiles).to eq(%w[test-profile1 test-profile2])
      end

    end

    it "copies the source container's configuration", :container, :delete_copy do
      container = client.container("test-container").to_hash
      config = container[:config]

      client.update_container("test-container",
        container.merge(config: config.merge("raw.lxc" => "lxc.aa_profile=unconfined")))

      client.copy_container("test-container", "test-container2")

      container = client.container("test-container2")
      expect(container.config["raw.lxc"]).to eq("lxc.aa_profile=unconfined")
    end

    context "when the source container is ephemeral", :container, :delete_copy do

      it "creates a persistent target container" do
        container = client.container("test-container").to_hash

        client.update_container("test-container",
          container.to_hash.merge(ephemeral: true))

        container = client.container("test-container")
        expect(container).to be_ephemeral

        client.copy_container("test-container", "test-container2")

        container = client.container("test-container2")
        expect(container).to_not be_ephemeral
      end

    end

    context "when an architecture is specified" do

      it "passes on the architecture" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test2",
            architecture: "i686",
            source: { type: "copy", source: "test" }
          })).
          to_return(ok_response)

        client.copy_container("test", "test2", architecture: "i686", sync: false)

        assert_requested request
      end

    end

    context "when a list of profiles is specified" do

      it "passes on the profiles" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test2",
            profiles: ['test1', 'test2'],
            source: { type: "copy", source: "test" }
          })).
          to_return(ok_response)

        client.copy_container("test", "test2", profiles: %w[test1 test2], sync: false)

        assert_requested request
      end

      it "overrides any profiles applied to the source container", :container, :profiles, :delete_copy do

        container1 = client.container("test-container")

        client.copy_container("test-container",
          "test-container2",
          profiles: %w[test-profile1 test-profile2])

        container2 = client.container("test-container2")

        expect(container1.profiles).to eq(%w[default])
        expect(container2.profiles).to eq(%w[test-profile1 test-profile2])
      end

    end

    context "when 'ephemeral: true' is specified" do

      it "passes it along" do

        request = stub_post("/1.0/containers").
          with(body: hash_including({
            name: "test2",
            ephemeral: true,
            source: { type: "copy", source: "test" }
          })).
          to_return(ok_response)

        client.copy_container("test", "test2", ephemeral: true, sync: false)

        assert_requested request
      end

      it "makes the container ephemeral", :container, :delete_copy do
        client.copy_container("test-container",
          "test-container2",
          ephemeral: true)

        container1 = client.container("test-container")
        container2 = client.container("test-container2")

        expect(container1).to_not be_ephemeral
        expect(container2).to be_ephemeral
      end

    end

    context "when 'ephemeral: true' is not specified", :container, :delete_copy do

      it "defaults to a persistent container" do
        client.copy_container("test-container", "test-container2")

        container1 = client.container("test-container")
        container2 = client.container("test-container2")

        expect(container1).to_not be_ephemeral
        expect(container2).to_not be_ephemeral
      end

    end

    context "when a config hash is specified" do

      it "passes on the configuration" do
        request = stub_post("/1.0/containers").
          with(body: hash_including({
              name: "test2",
              config: { hello: "world" },
              source: { type: "copy", source: "test" }
          })).
          to_return(ok_response)

        client.copy_container("test", "test2",
          config: { hello: "world" },
          sync: false)

        assert_requested request
      end

      it "stores the configuration with the container", :container, :delete_copy do
        client.copy_container("test-container",
          "test-container2",
          config: { "volatile.eth0.hwaddr" => "aa:bb:cc:dd:ee:ff" })

        container = client.container("test-container2")
        expect(container.config["volatile.eth0.hwaddr"]).to eq("aa:bb:cc:dd:ee:ff")
      end

      it "accepts non-String values", :container, :delete_copy do

        client.copy_container("test-container",
          "test-container2",
          config: { "limits.cpu" => 2 })

        container = client.container("test-container2")
        expect(container.config["limits.cpu"]).to eq("2")

      end

    end

  end

  describe ".snapshots", :vcr do

    it "returns an array of snapshots for a container", :container do
      snapshots = client.snapshots("test-container")
      expect(snapshots).to be_kind_of(Array)
    end

    it "makes the correct API call" do
      request = stub_get("/1.0/containers/test/snapshots").
        to_return(ok_response.merge(body: { metadata: [] }.to_json))

      snapshots = client.snapshots("test")
      assert_requested request
    end

    it "returns only the image names and not their paths" do

      body = { metadata: [
        "/1.0/containers/test/snapshots/test1",
        "/1.0/containers/test/snapshots/test2",
        "/1.0/containers/test/snapshots/test3",
        "/1.0/containers/test/snapshots/test4"
      ]}.to_json

      stub_get("/1.0/containers/test/snapshots").
        to_return(ok_response.merge(body: body))

      snapshots = client.snapshots("test")
      expect(snapshots).to eq(%w[test1 test2 test3 test4])
    end

  end

  describe ".snapshot", :vcr do

    it "retrieves a snapshot", :container, :snapshot do
      snapshot = client.snapshot("test-container", "test-snapshot")
      expect(snapshot.name).to eq("test-container/test-snapshot")
      expect(snapshot.architecture).to eq("x86_64")
    end

    it "makes the correct API call" do
      request = stub_get("/1.0/containers/test/snapshots/snap").to_return(ok_response)

      client.snapshot("test", "snap")
      assert_requested request
    end

  end

  describe ".create_snapshot", :vcr do

    it_behaves_like "an asynchronous operation" do

      before(:each) do
        lxd.create_container("test-container", alias: "cirros", sync: true)
      end

      after(:each) do
        lxd.delete_container("test-container", sync: true)
      end

      let(:operation) do
        lambda do |options|
          client.create_snapshot("test-container", "test-snapshot", options)
        end

      end

    end

    it "make the correct API call" do
      request = stub_post("/1.0/containers/test/snapshots").
        with(body: hash_including({
          name: "snap",
        })).
        to_return(ok_response.merge(body: { metadata: [] }.to_json))

      snapshots = client.create_snapshot("test", "snap", sync: false)
      assert_requested request
    end

    it "creates a snapshot of a stopped container", :container do
      client.create_snapshot("test-container", "test-snapshot")
      snapshots = client.snapshots("test-container")
      expect(snapshots).to include("test-snapshot")
    end

    it "creates a stateless snapshot of a running container", :container, :running do
      client.create_snapshot("test-container", "test-snapshot")

      snapshots = client.snapshots("test-container")
      expect(snapshots).to include("test-snapshot")

      snapshot = client.snapshot("test-container", "test-snapshot")
      expect(snapshot.stateful).to be_falsy
    end

    context "when 'stateful: true' is passed" do

      it "passes it to the server" do
        request = stub_post("/1.0/containers/test/snapshots").
          with(body: hash_including({
            name: "snap",
            stateful: true
          })).
          to_return(ok_response.merge(body: { metadata: [] }.to_json))

        snapshots = client.create_snapshot("test", "snap", stateful: true, sync: false)
        assert_requested request
      end

    end

  end

  describe ".delete_snapshot", :vcr do

    it_behaves_like "an asynchronous operation" do

      before(:each) do
        lxd.create_container("test-container", alias: "cirros", sync: true)
        lxd.create_snapshot("test-container", "test-snapshot", sync: true)
      end

      after(:each) do
        lxd.delete_container("test-container", sync: true)
      end

      let(:operation) do
        lambda do |options|
          client.delete_snapshot("test-container", "test-snapshot", options)
        end

      end

    end

    it "deletes the snapshot", :container, :snapshot do
      expect(client.snapshots("test-container")).to include("test-snapshot")
      client.delete_snapshot("test-container", "test-snapshot")
      expect(client.snapshots("test-container")).to_not include("test-snapshot")
    end

    it "makes the correct API call" do
      request = stub_delete("/1.0/containers/test/snapshots/snap").to_return(ok_response)
      client.delete_snapshot("test","snap", sync: false)
      assert_requested request
    end

  end

  describe ".rename_snapshot", :vcr do

    it_behaves_like "an asynchronous operation" do

      before(:each) do
        lxd.create_container("test-container", alias: "cirros", sync: true)
        lxd.create_snapshot("test-container", "test-snapshot", sync: true)
      end

      after(:each) do
        lxd.delete_container("test-container", sync: true)
      end

      let(:operation) do
        lambda do |options|
          client.rename_snapshot("test-container", "test-snapshot", "test-snapshot2", options)
        end

      end

    end

    it "renames a snapshot", :container, :snapshot do
      expect(client.snapshots("test-container")).to include("test-snapshot")
      expect(client.snapshots("test-container")).to_not include("test-snapshot2")

      client.rename_snapshot("test-container", "test-snapshot", "test-snapshot2")

      expect(client.snapshots("test-container")).to_not include("test-snapshot")
      expect(client.snapshots("test-container")).to include("test-snapshot2")
    end

    it "makes the correct API call" do
      request = stub_post("/1.0/containers/test/snapshots/snap").
        with(body: hash_including({
          name: "snap2"
        })).
        to_return(ok_response)

      client.rename_snapshot("test", "snap", "snap2", sync: false)
      assert_requested request
    end

  end

  describe ".restore_snapshot", :vcr do

    it_behaves_like "an asynchronous operation" do

      before(:each) do
        lxd.create_container("test-container", alias: "cirros", sync: true)
        lxd.create_snapshot("test-container", "test-snapshot", sync: true)
      end

      after(:each) do
        lxd.delete_container("test-container", sync: true)
      end

      let(:operation) do
        lambda do |options|
          client.restore_snapshot("test-container", "test-snapshot", options)
        end

      end

    end

    it "restores a snapshot", :container, :snapshot do

      container = client.container("test-container")
      container.config = container.config.to_hash.merge("limits.memory" => "256MB")

      client.update_container("test-container", container)

      client.write_file("test-container", "/tmp/test.txt", content: "test")
      expect { client.read_file("test-container", "/tmp/test.txt") }.to_not raise_error

      container_before = client.container("test-container")
      client.restore_snapshot("test-container", "test-snapshot")
      container_after = client.container("test-container")

      expect(container_before.config.to_hash).to have_key(:"volatile.apply_template")
      expect(container_after.config.to_hash).to have_key(:"volatile.apply_template")

      expect(container_before.config["limits.memory"]).to eq("256MB")
      expect(container_after.config["limits.memory"]).to be_nil
      expect { client.read_file("test-container", "/tmp/test.txt") }.to raise_error(Hyperkit::NotFound)

    end

    it "makes the correct API call" do
      request = stub_put("/1.0/containers/test").
        with(body: hash_including({
          restore: "snap"
        })).
        to_return(ok_response)

      client.restore_snapshot("test", "snap", sync: false)
      assert_requested request

    end

  end

  shared_examples_for "a file retrieval method" do

    context "when the source path does not exist" do

      it "raises an error", :container do
        expect { retrieval_method.call("test-container", "/qwe") }.to raise_error(Hyperkit::NotFound)
      end

    end

    context "when the source path is a directory" do

      it "raises an error", :container do
        expect { retrieval_method.call("test-container", "/etc") }.to raise_error(Hyperkit::BadRequest)
      end

    end

  end

  describe ".read_file", :vcr do

    it_behaves_like "a file retrieval method" do
      let(:retrieval_method) { lambda { |container, path| client.read_file(container, path) } }
    end

    context "when a valid file is specified" do

      it "makes the correct API call" do

        request = stub_get("/1.0/containers/test/files?path=/etc/passwd&url_encode=false").
          to_return(ok_response)

        client.read_file("test", "/etc/passwd")
        assert_requested request

      end

      it "returns the file contents", :container do
        response = client.read_file("test-container", "/etc/passwd")
        expect(response).to include("cirros:x:1000:1000")
      end

    end

  end

  describe ".pull_file", :vcr do

    it_behaves_like "a file retrieval method" do
      let(:retrieval_method) { lambda { |container, path| client.pull_file(container, path, "/tmp/test.txt") } }
    end

    it "makes the correct API call" do

      request = stub_get("/1.0/containers/test/files?path=/etc/passwd&url_encode=false").
        to_return(ok_response)

      Dir.mktmpdir do |dir|
        client.pull_file("test", "/etc/passwd", File.join(dir, "test-passwd"))
        assert_requested request
      end

    end

    it "saves the file to the specified filename", :container do

      Dir.mktmpdir do |dir|
        output_file = File.join(dir, "test-passwd")
        client.pull_file("test-container", "/etc/passwd", output_file)
        expect(File.exist?(output_file)).to be_truthy
      end

    end

    it "writes the content of the file to the object", :container do

      output = StringIO.new
      client.pull_file("test-container", "/etc/passwd", output)
      expect(output.read.empty?).to be true
    end

    it "writes the file with the permissions of the original file", :container do

      Dir.mktmpdir do |dir|
        output_file = File.join(dir, "test-passwd")
        client.pull_file("test-container", "/etc/passwd", output_file)
        expect(File.stat(output_file).mode & 0777).to eq(0600)
      end

    end

    it "returns the full path of the output file", :container do

      Dir.mktmpdir do |dir|
        output_file = File.join(dir, "test-passwd")
        ret_val = client.pull_file("test-container", "/etc/passwd", output_file)
        expect(ret_val).to eq(output_file)
      end

    end

    context "when the path to the output path does not exist" do

      it "raises an error", :container do

        Dir.mktmpdir do |dir|
          call = lambda do
            client.pull_file("test-container", "/etc/passwd", File.join(dir,"test/test"))
          end
          expect(call).to raise_error(Errno::ENOENT)
        end

      end

    end

    context "when the output path is a directory" do

      it "raises an error", :container do

        Dir.mktmpdir do |dir|
          test = lambda do
            begin
              client.pull_file("test-container", "/etc/passwd", dir)
              return false
            rescue => ex
              return ex.is_a?(Errno::EISDIR) || ex.is_a?(Errno::EACCES)
            end
          end

          # This test is a bit convoluted since JRuby throws a different
          # error (EACCES) than the rest of them.  RSpec has deprecated
          # the use of the raise_error matcher without specifying the
          # error being raised, and does not allow raise_error to be used
          # in compound expectations.  Hence, the weirdness...
          expect(test.call).to be_truthy
        end

      end

    end

  end

  shared_examples_for "a file writing method" do

    it "accepts a uid", :container do

      write_method.call("/tmp/test.txt", uid: 0)
      write_method.call("/tmp/test2.txt", uid: 1000)

      client.read_file("test-container", "/tmp/test.txt")
      expect(client.last_response.headers["x-lxd-uid"]).to eq("0")

      client.read_file("test-container", "/tmp/test2.txt")
      expect(client.last_response.headers["x-lxd-uid"]).to eq("1000")

    end

    it "accepts a gid", :container do

      write_method.call("/tmp/test.txt", gid: 0)
      write_method.call("/tmp/test2.txt", gid: 1000)

      client.read_file("test-container", "/tmp/test.txt")
      expect(client.last_response.headers["x-lxd-gid"]).to eq("0")

      client.read_file("test-container", "/tmp/test2.txt")
      expect(client.last_response.headers["x-lxd-gid"]).to eq("1000")

    end

    it "accepts a mode", :container do

      write_method.call("/tmp/test.txt", mode: 0427)
      write_method.call("/tmp/test2.txt", mode: 0777)

      client.read_file("test-container", "/tmp/test.txt")
      expect(client.last_response.headers["x-lxd-mode"]).to eq("0427")

      client.read_file("test-container", "/tmp/test2.txt")
      expect(client.last_response.headers["x-lxd-mode"]).to eq("0777")

    end

  end

  describe ".write_file", :vcr do

    context "when given a block" do

      it_behaves_like "a file writing method" do
        let(:write_method) do
          lambda do |filename, options|
            client.write_file("test-container", filename, options) do |f|
              f.puts "Testing"
            end
          end
        end
      end

      it "yields a StringIO object", :container do

        client.write_file("test-container", "/tmp/test.txt") do |f|
          expect(f).to be_a(StringIO)
        end

      end

      it "writes the contents of the IO object at the end of the block", :container do

        client.write_file("test-container", "/tmp/test.txt") do |f|
          f.print "Hello "
          f.puts "world!"
        end

        expect(client.read_file("test-container", "/tmp/test.txt")).to eq("Hello world!\n")

      end

    end

    context "when given no block" do

      it_behaves_like "a file writing method" do
        let(:write_method) do
          lambda do |filename, options|
            client.write_file("test-container", filename, options.merge(content: "test"))
            client.write_file("test-container", filename, options.merge(content: "test"))
          end
        end
      end

      it "writes the contents of the 'content' option to the file", :container do
        client.write_file("test-container", "/tmp/test.txt", content: "this is a test")
        expect(client.read_file("test-container", "/tmp/test.txt")).to eq("this is a test")
      end

      context "and no content option is passed" do

        it "creates an empty file", :container do
          client.write_file("test-container", "/tmp/test.txt", uid: 1000)
          expect(client.read_file("test-container", "/tmp/test.txt")).to eq("")
          expect(client.last_response.headers["x-lxd-uid"]).to eq("1000")
        end

      end

    end

  end

  describe ".push_file", :vcr do

    it_behaves_like "a file writing method" do
      let(:write_method) do
        lambda do |path, options|
          file = Tempfile.new("hyperkit-push_file")
          file.write("hello world")
          file.close
          client.push_file(file.path, "test-container", path, options)
        end
      end
    end

    it "copies the local file to the container", :container do
      file = Tempfile.new("hyperkit-push_file")
      file.puts("hello world")
      file.print("testing!")
      file.close

      client.push_file(file.path, "test-container", "/tmp/push.txt")
      expect(client.read_file("test-container", "/tmp/push.txt")).to eq("hello world\ntesting!")
    end

    it "writes the content of an IO object to the container", :container do
      io = StringIO.new("hello world\ntesting!")

      client.push_file(io, "test-container", "/tmp/push.txt")
      expect(client.read_file("test-container", "/tmp/push.txt")).to eq("hello world\ntesting!")
    end
  end

  describe ".logs", :vcr do

    it "returns an array of logs", :container do
      logs = client.logs("test-container")
      expect(logs).to be_kind_of(Array)
    end

    it "makes the correct API call" do

      request = stub_get("/1.0/containers/test/logs").
        to_return(ok_response.merge(body: { metadata: [] }.to_json))

      client.logs("test")
      assert_requested request
    end

    it "returns only the image names and not their paths" do

      body = { metadata: [
        "/1.0/containers/test/logs/test1",
        "/1.0/containers/test/logs/test2",
        "/1.0/containers/test/logs/test3",
        "/1.0/containers/test/logs/test4"
      ]}.to_json

      stub_get("/1.0/containers/test/logs").
        to_return(ok_response.merge(body: body))

      logs = client.logs("test")
      expect(logs).to eq(%w[test1 test2 test3 test4])
    end

  end

  describe ".log", :vcr do

    it "makes the correct API call" do
      request = stub_get("/1.0/containers/test/logs/lxc.log").
        to_return(ok_response)

      client.log("test","lxc.log")
      assert_requested request
    end

    it "retrieves a log", :container do
      logs = client.logs("test-container")
      log = client.log("test-container", logs.first)
      expect(log).to include("INFO")
    end

  end

  describe ".delete_log", :vcr do

    it "deletes the log", :container do
      logs = client.logs("test-container")
      expect(logs).to_not be_empty

      log = logs.first

      response = client.delete_log("test-container", log)
      expect(client.logs("test-container")).to_not include(log)

    end

    it "makes the correct API call" do
      request = stub_delete("/1.0/containers/test/logs/lxc.log").to_return(ok_response)
      client.delete_log("test", "lxc.log")
      assert_requested request
    end

  end

  describe ".execute_command", :vcr do

    it_behaves_like "an asynchronous operation" do

      before(:each) do
        lxd.create_container("test-container", alias: "cirros", sync: true)
        lxd.start_container("test-container", sync: true)
      end

      after(:each) do
        lxd.stop_container("test-container", force: true, sync: true)
        lxd.delete_container("test-container", sync: true)
      end

      let(:operation) do
        lambda do |options|
          client.execute_command("test-container", "echo 'hello'", options)
        end

      end

    end

    it "runs the specified command in the container", :container, :running do
      expect { client.read_file("test-container", "/tmp/test.txt") }.to raise_error(Hyperkit::NotFound)
      client.execute_command("test-container", ["/bin/sh","-c","echo 'hello world' | tee /tmp/test.txt"])
      expect(client.read_file("test-container", "/tmp/test.txt")).to eq("hello world\n")
    end

    it "accepts environment variables", :container, :running do
      expect { client.read_file("test-container", "/tmp/test.txt") }.to raise_error(Hyperkit::NotFound)

      client.execute_command("test-container",
        "/bin/sh -c 'echo \"$MYVAR\" $MYVAR2 > /tmp/test.txt'",
        environment: {
          MYVAR: "environment  test",
          MYVAR2: 42
        }
      )

      expect(client.read_file("test-container", "/tmp/test.txt")).to eq("environment  test 42\n")
    end

    context "when the command is given as an array" do

      it "makes the correct API call" do
        request = stub_post("/1.0/containers/test/exec").
          with(body: hash_including({
            command: ["bash", "-c", "echo \"hello world\" | tee -a /tmp/test.txt"]
          })).
          to_return(ok_response)

        client.execute_command("test", "bash -c 'echo \"hello world\" | tee -a /tmp/test.txt'", sync: false)
        assert_requested request
      end

    end

    context "when the command is given as a string" do

      it "makes the correct API call" do
        request = stub_post("/1.0/containers/test/exec").
          with(body: hash_including({
            command: ["bash", "-c", "echo \"hello world\" | tee -a /tmp/test.txt"]
          })).
          to_return(ok_response)

        client.execute_command("test", ["bash", "-c", "echo \"hello world\" | tee -a /tmp/test.txt"], sync: false)
        assert_requested request
      end

    end

    it "raises an error if the container is not running", :container do
      call = lambda { client.execute_command("test-container", "echo hello") }
      expect(call).to raise_error(Hyperkit::BadRequest)
    end

  end

end
