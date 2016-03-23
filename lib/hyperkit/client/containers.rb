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
        response.metadata.map { |path| path.split('/').last }
      end

      # Get information on a container
      #
      # @param name [String] Container name
      # @return [Sawyer::Resource] Container information
      #
      # @example Get information about a container
      #   Hyperkit.client.container("test-container") #=> {
      #     :architecture => "x86_64",
      #       :config => {
      #         :"volatile.base_image" => "097e75d6f7419d3a5e204d8125582f2d7bdd4ee4c35bd324513321c645f0c415",
      #         :"volatile.eth0.hwaddr" => "00:16:3e:24:5d:7a",
      #         :"volatile.eth0.name" => "eth0",
      #         :"volatile.last_state.idmap" =>
      #           "[{\"Isuid\":true,\"Isgid\":false,\"Hostid\":165536,\"Nsid\":0,\"Maprange\":65536},{\"Isuid\":false,\"Isgid\":true,\"Hostid\":165536,\"Nsid\":0,\"Maprange\":65536}]"
			#       },
      #       :created_at => 2016-03-18 20:55:26 UTC,
      #       :devices => {
			#         :root => {:path => "/", :type => "disk"}
			#       },
      #       :ephemeral => false,
      #       :expanded_config => {
      #         :"volatile.base_image" => "097e75d6f7419d3a5e204d8125582f2d7bdd4ee4c35bd324513321c645f0c415",
      #         :"volatile.eth0.hwaddr" => "00:16:3e:24:5d:7a",
      #         :"volatile.eth0.name" => "eth0",
      #         :"volatile.last_state.idmap" =>
      #           "[{\"Isuid\":true,\"Isgid\":false,\"Hostid\":165536,\"Nsid\":0,\"Maprange\":65536},{\"Isuid\":false,\"Isgid\":true,\"Hostid\":165536,\"Nsid\":0,\"Maprange\":65536}]"
      #       },
      #       :expanded_devices => {
      #         :eth0 => { :nictype => "bridged", :parent => "lxcbr0", :type => "nic"},
      #         :root => { :path => "/", :type => "disk"}
      #       },
      #       :name => "test-container",
      #       :profiles => ["default"],
      #       :stateful => false,
      #       :status => "Stopped",
      #       :status_code => 102
      #   }
      def container(name)
        get(container_path(name)).metadata
      end

      # Retrieve the current state of a container
      #
      # @param name [String] Container name
      # @return [Sawyer::Resource] Container state
      #
      # @example Get container state
      #   Hyperkit.client.container_state("test-container") #=> {
      #   }
      def container_state(name)
        url = File.join(container_path(name), "state")
        get(url).metadata
      end

      private

      def container_path(name)
        File.join(containers_path, name)
      end

      def containers_path
        "/1.0/containers"
      end
 
    end

  end

end

