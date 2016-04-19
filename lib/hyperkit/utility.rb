module Hyperkit

  # Utility methods for Hyperkit
  module Utility

    private

    # Stringify the keys and values of a hash
    #
    # LXD often chokes on non-String JSON values.  This method simply
    # takes a Hash and stringifies its keys and values.  The result
    # can then be converted to JSON and passed to LXD.
    #
    # @param input [Hash] Original Hash
    # @return A copy of the Hash, with its keys and values stringified
    def stringify_hash(input)
      input.inject({}){|h,(k,v)| h[k.to_s] = v.to_s; h}
	  end

  end

end
