module Hyperkit

  class Client

    # Methods for the networks API
    # 
    # @see https://github.com/lxc/lxd/blob/master/specs/rest-api.md
    module Networks

      # List of networks defined on the host
      #
      # @return [Array<String>] An array of networks defined on the host
      def networks
        response = get networks_path
        response[:metadata].map { |path| path.split('/').last }
      end

      private

      def networks_path
        "/1.0/networks"
      end
 
    end

  end

end

