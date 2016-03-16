module Hyperkit

  class Client

    # Methods for the networks API
    # 
    # @see https://github.com/lxc/lxd/blob/master/specs/rest-api.md
    module Networks

      # List of networks defined on the host
      #
      # @return [Array<String>] An array of networks defined on the host
      # @example Get list of networks
      #   Hyperkit.client.networks #=> ["lo", "eth0", "lxcbr0"]
      def networks
        response = get networks_path
        response[:metadata].map { |path| path.split('/').last }
      end

      # Get information on a network
      #
      # @return [Hash] A hash of information about the network
      # @example Get information about lxcbr0
      #   Hyperkit.client.network("lxcbr0") #=> {:name=>"lxcbr0", :type=>"bridge", :used_by=>[]}
      def network(name)
        response = get network_path(name)
        response[:metadata]
      end

      private

      def network_path(name)
        File.join(networks_path, name)
      end

      def networks_path
        "/1.0/networks"
      end
 
    end

  end

end

