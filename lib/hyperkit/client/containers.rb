module Hyperkit

  class Client

    # Methods for the containers API
    # 
    # @see https://github.com/lxc/lxd/blob/master/specs/rest-api.md
    module Containers

      # List of containers on the server (public or private)
      #
      # @return [Array<String>] An array of container names
      # @example Get list of containers
      #   Hyperkit.client.containers #=> ["container1", "container2", "container3"]
      def containers
        response = get containers_path 
        response[:metadata].map { |path| path.split('/').last }
      end

      private

      def containers_path
        "/1.0/containers"
      end
 
    end

  end

end

