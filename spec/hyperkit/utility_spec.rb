require 'spec_helper'

describe Hyperkit::Utility do

  let(:client) { lxd }

  describe ".stringify_hash" do

    let(:input) { { one: 2, hello: true } }

    it "returns a stringifed version of the input hash" do
      result = client.send(:stringify_hash, input)
      expect(result).to have_key("one")
      expect(result).to have_key("hello")
      expect(result["one"]).to eq("2")
      expect(result["hello"]).to eq("true")

      expect(result).to_not have_key(:one)
      expect(result).to_not have_key(:hello)
    end

    it "does not modify the original hash" do
      client.send(:stringify_hash, input)

      expect(input).to have_key(:one)
      expect(input).to have_key(:hello)
      expect(input[:one]).to eq(2)
      expect(input[:hello]).to eq(true)

      expect(input).to_not have_key("one")
      expect(input).to_not have_key("hello")
    end

  end

end
