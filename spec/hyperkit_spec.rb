require 'spec_helper'

describe Hyperkit do
  before do
    Hyperkit.reset!
  end

  after do
    Hyperkit.reset!
  end

  it "sets defaults" do
    Hyperkit::Configurable.keys.each do |key|
      expect(Hyperkit.instance_variable_get(:"@#{key}")).to eq(Hyperkit::Default.send(key))
    end
  end

  describe ".client" do
    it "creates an Hyperkit::Client" do
      expect(Hyperkit.client).to be_kind_of Hyperkit::Client
    end
    it "caches the client when the same options are passed" do
      expect(Hyperkit.client).to eq(Hyperkit.client)
    end
    it "returns a fresh client when options are not the same" do
      client = Hyperkit.client
      Hyperkit.client_cert = '/tmp/qwe'
      client_two = Hyperkit.client
      client_three = Hyperkit.client
      expect(client).not_to eq(client_two)
      expect(client_three).to eq(client_two)
    end
  end

  describe ".configure" do
    Hyperkit::Configurable.keys.each do |key|
      it "sets the #{key.to_s.gsub('_', ' ')}" do
        Hyperkit.configure do |config|
          config.send("#{key}=", key)
        end
        expect(Hyperkit.instance_variable_get(:"@#{key}")).to eq(key)
      end
    end
  end

end

