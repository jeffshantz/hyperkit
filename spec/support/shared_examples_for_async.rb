require 'spec_helper'

RSpec.shared_examples_for "an asynchronous operation" do

  context "by default" do

    it "returns a synchronous result" do
      expect(client.auto_sync).to eq(true)

      response = operation.call({})

      expect(response.id).to_not be_nil
      expect(response.status).to eq("Success")
      expect(response.status_code).to eq(200)
    end

  end

  context "when sync: false is passed" do

    it "returns details about a background operation" do
      expect(client.auto_sync).to eq(true)

      response = operation.call({sync: false})

      expect(response.id).to_not be_nil
      expect(response.status).to eq("Running")
      expect(response.status_code).to eq(103)

      client.wait_for_operation(response.id)
    end

  end

  context "when auto_sync is false" do

    before(:each) do
      client.auto_sync = false
    end

    it "returns details about a background operation" do
      expect(client.auto_sync).to eq(false)
      response = operation.call({})

      expect(response.id).to_not be_nil
      expect(response.status).to eq("Running")
      expect(response.status_code).to eq(103)

      client.wait_for_operation(response.id)
    end

    context "and sync: true is passed" do

      it "returns a synchronous result" do
        expect(client.auto_sync).to eq(false)

        response = operation.call({sync: true})

        expect(response.id).to_not be_nil
        expect(response.status).to eq("Success")
        expect(response.status_code).to eq(200)
      end

    end

  end

end
