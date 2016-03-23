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

  describe ".container", :vcr do

    it "retrieves a container" do
      # TODO: Create a container

      container = client.container("test-container")

      expect(container.name).to eq("test-container")
      expect(container.architecture).to eq("x86_64")
      
      # TODO: Delete the container
    end

    it "makes the correct API call" do
      request = stub_get("/1.0/containers/test").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.container("test")
      assert_requested request
    end

  end

  describe ".container_state", :vcr do

    it "returns the current state of a container" do

      # TODO: Create a container

      state = client.container_state("test-container")

      expect(state.status).to eq("Running")
      expect(state.network.lo.type).to eq("loopback")
      expect(state.pid).to be_a(Fixnum)

      # TODO: Delete the container
    end

    it "makes the correct API call" do
      request = stub_get("/1.0/containers/test/state").
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.container_state("test")
      assert_requested request
    end

  end

  describe ".start_container", :vcr do

    it  "starts a stopped container" do
      # TODO: Create and stop a container

      state = client.container_state("test-container")
      expect(state.status).to eq("Stopped")

      response = client.start_container("test-container")
      client.wait_for_operation(response.id)

      state = client.container_state("test-container")
      expect(state.status).to eq("Running")

      # TODO: Delete the container
    end

    it "accepts a timeout" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "start",
          timeout: 30
        })).
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.start_container("test", timeout: 30)
      assert_requested request
    end

    it "allows the operation to be stateful" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "start",
          stateful: true
        })).
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.start_container("test", stateful: true)
      assert_requested request
    end

  end


  describe ".stop_container", :vcr do

    it "stops a running container" do
      # TODO: Create and start a container

      state = client.container_state("test-container")
      expect(state.status).to eq("Running")

      response = client.stop_container("test-container", force: true)
      client.wait_for_operation(response.id)

      state = client.container_state("test-container")
      expect(state.status).to eq("Stopped")

      # TODO: Delete the container
    end

    it "throws an error if the container is not running" do
      # TODO: Create and stop a container

      state = client.container_state("test-container")
      expect(state.status).to eq("Stopped")

      response = client.stop_container("test-container")
      expect { client.wait_for_operation(response.id) }.to raise_error(Hyperkit::BadRequest)

      # TODO: Delete the container
    end

    it "accepts a timeout" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "stop",
          timeout: 30
        })).
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.stop_container("test", timeout: 30)
      assert_requested request
    end

    it "allows the operation to be forced" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "stop",
          force: true
        })).
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.stop_container("test", force: true)
      assert_requested request
    end

    it "allows the operation to be stateful" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "stop",
          stateful: true
        })).
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.stop_container("test", stateful: true)
      assert_requested request
    end

  end

  describe ".restart_container", :vcr do

    it "restarts a running container" do
      # TODO: Create and start container

      response = client.start_container("test-container")
      client.wait_for_operation(response.id)

      state = client.container_state("test-container")
      expect(state.status).to eq("Running")
      pid_before = state.pid

      response = client.restart_container("test-container", force: true)
      client.wait_for_operation(response.id)

      state = client.container_state("test-container")
      expect(state.status).to eq("Running")
      pid_after = state.pid
      
      expect(pid_after).to_not eq(pid_before)

      # TODO: Delete the container
    end

    it "throws an error if the container is not running" do
      # TODO: Create and stop a container

      response = client.stop_container("test-container", force: true)
      client.wait_for_operation(response.id)

      state = client.container_state("test-container")
      expect(state.status).to eq("Stopped")

      response = client.restart_container("test-container")
      expect { client.wait_for_operation(response.id) }.to raise_error(Hyperkit::BadRequest)

      # TODO: Delete the container
    end

    it "allows the operation to be forced" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "restart",
          force: true
        })).
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.restart_container("test", force: true)
      assert_requested request
    end

    it "accepts a timeout" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "restart",
          timeout: 30
        })).
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.restart_container("test", timeout: 30)
      assert_requested request
    end

  end

  describe ".freeze_container", :vcr do

    it "suspends a running container" do
      # TODO: Create and start container

      state = client.container_state("test-container")
      expect(state.status).to eq("Running")

      response = client.freeze_container("test-container")
      client.wait_for_operation(response.id)

      state = client.container_state("test-container")
      expect(state.status).to eq("Frozen")

      # TODO: Delete the container
      
    end

    it "throws an error if the container is not running" do
      # TODO: Create and stop a container

      state = client.container_state("test-container")
      expect(state.status).to eq("Stopped")

      response = client.freeze_container("test-container")
      expect { client.wait_for_operation(response.id) }.to raise_error(Hyperkit::BadRequest)

      # TODO: Delete the container
    end

    it "accepts a timeout" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "freeze",
          timeout: 30
        })).
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.freeze_container("test", timeout: 30)
      assert_requested request
    end

  end

  describe ".unfreeze_container", :vcr do

    it "resumes a frozen container" do
      # TODO: Create and freeze container

      state = client.container_state("test-container")
      expect(state.status).to eq("Frozen")

      response = client.unfreeze_container("test-container")
      client.wait_for_operation(response.id)

      state = client.container_state("test-container")
      expect(state.status).to eq("Running")

      # TODO: Delete the container
      
    end

    it "throws an error if the container is not frozen" do
      # TODO: Create and start a container

      state = client.container_state("test-container")
      expect(state.status).to eq("Running")

      response = client.unfreeze_container("test-container")
      expect { client.wait_for_operation(response.id) }.to raise_error(Hyperkit::BadRequest)

      # TODO: Delete the container
    end

    it "accepts a timeout" do
      request = stub_put("/1.0/containers/test/state").
        with(body: hash_including({
          action: "unfreeze",
          timeout: 30
        })).
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      client.unfreeze_container("test", timeout: 30)
      assert_requested request
    end

  end

end
