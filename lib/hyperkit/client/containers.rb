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

      # Update the configuration of a container.
      #
      # Configuration is overwritten, not merged.  Accordingly, clients should
      # first call container to obtain the current configuration of a
      # container.  The resulting object should be modified and then passed to
      # update_container.
      #
      # Note that LXD does not allow certain attributes to be changed (e.g.
      # <code>status</code>, <code>status_code</code>, <code>stateful</code>,
      # <code>name</code>, etc.) through this call.
      #
      # @param name [String] Container name
      # @param config [Sawyer::Resource|Hash] Container configuration obtained from #container
      #
      # @example Add 'eth1' device to a container
      #   container = Hyperkit.client.container("test-container")
			#   container.devices.eth1 = {nictype: "bridged", parent: "lxcbr0", type: "nic"}
      #   Hyperkit.client.update_container("test-container", container)
      #
      # @example Change container to be ephemeral (i.e. it will be deleted when stopped)
      #   container = Hyperkit.client.container("test-container")
			#   container.ephemeral = true
      #   Hyperkit.client.update_container("test-container", container)
      #   
      # @example Change container's AppArmor profile to 'unconfined'.
      #   container = Hyperkit.client.container("test-container")
      #
      #   # Note: due to a bug in Sawyer::Resource, the following will fail
      #   container.config[:"raw.lxc"] = "lxc.aa_profile=unconfined"
      #
      #   # Instead, convert 'config' to a Hash, and update the Hash
      #   container.config = container.config.to_hash
      #   container.config["raw.lxc"] = "lxc.aa_profile=unconfined"
      #
      #   Hyperkit.client.update_container("test-container", container)
      #
      def update_container(name, config)
        put(container_path(name), config.to_hash).metadata
      end

      def rename_container(old_name, new_name)
        post(container_path(old_name), { "name": new_name }).metadata
      end

      # Delete a container.  Throws an error if the container is running.
      #
      # @param name [String] Container name
      #
      # @example Delete container "test"
      #   Hyperkit.client.delete_container("test")
      #
      def delete_container(name)
        delete(container_path(name)).metadata
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
        get(container_state_path(name)).metadata
      end

      # Start a container
      #
      # @param name [String] Container name
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :stateful Whether to restore previously saved runtime state (default: <code>false</false>)
      # @option options [Fixnum] :timeout Time after which the operation is considered to have failed (default: no timeout)
      #
      # @example Start container
      #   Hyperkit.client.start_container("test")
      #
      # @example Start container and restore previously saved runtime state
      #   # Stop the container and save its runtime state
      #   Hyperkit.client.stop_container("test", stateful: true)
      #
      #   # Start the container and restore its runtime state
      #   Hyperkit.client.start_container("test", stateful: true)
      #
      # @example Start container with a timeout
      #   Hyperkit.client.start_container("test", timeout: 30)
      def start_container(name, options={})
        opts = options.slice(:stateful, :timeout)
        response = put(container_state_path(name), opts.merge(action: "start"))
        response.metadata
      end

      # Stop a container
      #
      # @param name [String] Container name
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :stateful Whether to restore previously saved runtime state (default: <code>false</false>)
      # @option options [Boolean] :force Whether to force the operation by killing the container
      # @option options [Fixnum] :timeout Time after which the operation is considered to have failed (default: no timeout)
      #
      # @example Stop container
      #   Hyperkit.client.stop_container("test")
      #
      # @example Stop container and save its runtime state
      #   # Stop the container and save its runtime state
      #   Hyperkit.client.stop_container("test", stateful: true)
      #
      #   # Start the container and restore its runtime state
      #   Hyperkit.client.start_container("test", stateful: true)
      #
      # @example Stop the container forcefully (i.e. kill it)
      #   Hyperkit.client.stop_container("test", force: true)
      def stop_container(name, options={})

        opts = options.slice(:force, :stateful, :timeout)
        response = put(container_state_path(name), opts.merge(action: "stop"))
        response.metadata

      end

      # Restart a running container
      #
      # @param name [String] Container name
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :force Whether to force the operation by killing the container
      # @option options [Fixnum] :timeout Time after which the operation is considered to have failed (default: no timeout)
      #
      # @example Restart container
      #   Hyperkit.client.restart_container("test")
      #
      # @example Restart container forcefully
      #   Hyperkit.client.restart_container("test", force: true)
      #
      # @example Restart container with timeout
      #   Hyperkit.client.restart_container("test", timeout: 30)
      def restart_container(name, options={})

        opts = options.slice(:force, :timeout)
        response = put(container_state_path(name), opts.merge(action: "restart"))
        response.metadata

      end

      # Freeze (suspend) a running container
      #
      # @param name [String] Container name
      # @param options [Hash] Additional data to be passed
      # @option options [Fixnum] :timeout Time after which the operation is considered to have failed (default: no timeout)
      #
      # @example Suspend container
      #   Hyperkit.client.freeze_container("test")
      #
      # @example Suspend container with timeout
      #   Hyperkit.client.freeze_container("test", timeout: 30)
      def freeze_container(name, options={})

        opts = options.slice(:timeout)
        response = put(container_state_path(name), opts.merge(action: "freeze"))
        response.metadata

      end

      alias_method :pause_container, :freeze_container
      alias_method :suspend_container, :freeze_container

      # Unfreeze (resume) a frozen container
      #
      # @param name [String] Container name
      # @param options [Hash] Additional data to be passed
      # @option options [Fixnum] :timeout Time after which the operation is considered to have failed (default: no timeout)
      #
      # @example Resume container
      #   Hyperkit.client.unfreeze_container("test")
      #
      # @example Resume container with timeout
      #   Hyperkit.client.unfreeze_container("test", timeout: 30)
      def unfreeze_container(name, options={})

        opts = options.slice(:timeout)
        response = put(container_state_path(name), opts.merge(action: "unfreeze"))
        response.metadata

      end

      # Prepare to migrate a container.  Generates secrets to be passed to #migrate_container.
      #
      # Note that CRIU must be installed on the server, or LXD will return a
      # 500 error.  On Ubuntu, you can install it with 
      # <code>sudo apt-get install criu</code>.
      #
      # @param name [String] Container name
      #
      # @example Generate migration secrets for container "test"
      #   Hyperkit.client.prepare_container_for_migration("test") #=> {
      #    :control=>"f972d7b34a5a6dab7592a18bcd3f0b144d013861826518cdfd44083d5d942f97",
      #    :criu=>"3788b604669033f3cc8705772f51d8c9d7377a6705bca2bae156cf2bd6799291",
      #    :fs=>"6783685058a694c77651187fa93d2113d2ba8cb56b24a69ed3f3dc98bb74642f"
      #  }
      def prepare_container_for_migration(name)
        post(container_path(name), { "migration": true }).metadata.metadata
      end

      alias_method :resume_container, :unfreeze_container

      private

      def container_state_path(name)
        File.join(container_path(name), "state")
      end

      def container_path(name)
        File.join(containers_path, name)
      end

      def containers_path
        "/1.0/containers"
      end
 
    end

  end

end
