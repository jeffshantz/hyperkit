require 'active_support/core_ext/array/extract_options'
require 'shellwords'

module Hyperkit

  class Client

    # Methods for the containers API
    #
    # @see Hyperkit::Client
    # @see https://github.com/lxc/lxd/blob/master/specs/rest-api.md
    module Containers

      # @!group Retrieval

      # List of containers on the server (public or private)
      #
      # @return [Array<String>] An array of container names
      #
      # @example Get list of containers
      #   Hyperkit.containers #=> ["container1", "container2", "container3"]
      def containers
        response = get(containers_path)
        response.metadata.map { |path| path.split('/').last }
      end

      # Get information on a container
      #
      # @param name [String] Container name
      # @return [Sawyer::Resource] Container information
      #
      # @example Get information about a container
      #   Hyperkit.container("test-container") #=> {
      #     :architecture => "x86_64",
      #     :config => {
      #       :"volatile.base_image" => "097e75d6f7419d3a5e204d8125582f2d7bdd4ee4c35bd324513321c645f0c415",
      #       :"volatile.eth0.hwaddr" => "00:16:3e:24:5d:7a",
      #       :"volatile.eth0.name" => "eth0",
      #       :"volatile.last_state.idmap" =>
      #         "[{\"Isuid\":true,\"Isgid\":false,\"Hostid\":165536,\"Nsid\":0,\"Maprange\":65536},{\"Isuid\":false,\"Isgid\":true,\"Hostid\":165536,\"Nsid\":0,\"Maprange\":65536}]"
      #     },
      #     :created_at => 2016-03-18 20:55:26 UTC,
      #     :devices => {
      #       :root => {:path => "/", :type => "disk"}
      #     },
      #     :ephemeral => false,
      #     :expanded_config => {
      #       :"volatile.base_image" => "097e75d6f7419d3a5e204d8125582f2d7bdd4ee4c35bd324513321c645f0c415",
      #       :"volatile.eth0.hwaddr" => "00:16:3e:24:5d:7a",
      #       :"volatile.eth0.name" => "eth0",
      #       :"volatile.last_state.idmap" =>
      #         "[{\"Isuid\":true,\"Isgid\":false,\"Hostid\":165536,\"Nsid\":0,\"Maprange\":65536},{\"Isuid\":false,\"Isgid\":true,\"Hostid\":165536,\"Nsid\":0,\"Maprange\":65536}]"
      #     },
      #     :expanded_devices => {
      #       :eth0 => { :nictype => "bridged", :parent => "lxcbr0", :type => "nic"},
      #       :root => { :path => "/", :type => "disk"}
      #     },
      #     :name => "test-container",
      #     :profiles => ["default"],
      #     :stateful => false,
      #     :status => "Stopped",
      #     :status_code => 102
      #   }
      def container(name)
        get(container_path(name)).metadata
      end

      # @!endgroup

      # @!group Creation

      # Create a container from an image (local or remote).  The container will
      # be created in the <code>Stopped</code> state.
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param name [String] Container name
      # @param options [Hash] Additional data to be passed
      # @option options [String] :alias Alias of the source image.  <b>Either <code>:alias</code>, <code>:fingerprint</code>, <code>:properties</code>, or <code>empty: true</code> must be specified</b>.
      # @option options [String] :architecture Architecture of the container (e.g. <code>x86_64</code>).  By default, this will be obtained from the image metadata
      # @option options [String] :certificate PEM certificate to use to authenticate with the remote server. If not specified, and the source image is private, the target LXD server's certificate is used for authentication.  <b>This option is valid only when transferring an image from a remote server using the <code>:server</code> option.</b>
      # @option options [Hash] :config Container configuration
      # @option options [Boolean] :ephemeral Whether to make the container ephemeral (i.e. delete it when it is stopped; default: <code>false</code>)
      # @option options [Boolean] :empty Whether to make an empty container (i.e. not from an image).  Specifying <code>true</code> will cause LXD to create a container with no rootfs.  That is, /var/lib/lxd/<container-name> will simply be an empty directly.  One can then create a rootfs directory within this directory and populate it manually.  This is useful when migrating LXC containers to LXD.
      # @option options [String] :fingerprint SHA-256 fingerprint of the source image.  This can be a prefix of a fingerprint, as long as it is unambiguous.  <b>Either <code>:alias</code>, <code>:fingerprint</code>, <code>:properties</code>, or <code>empty: true</code> must be specified</b>.
      # @option options [Array] :profiles List of profiles to be applied to the container (default: <code>[]</code>)
      # @option options [String] :properties Properties of the source image.  <b>Either <code>:alias</code>, <code>:fingerprint</code>, <code>:properties</code>, or <code>empty: true</code> must be specified</b>.
      # @option options [String] :protocol Protocol to use in transferring the image (<code>lxd</code> or <code>simplestreams</code>; defaults to <code>lxd</code>).  <b>This option is valid only when transferring an image from a remote server using the <code>:server</code> option.</b>
      # @option options [String] :secret Secret to use to retrieve the image.  <b>This option is valid only when transferring an image from a remote server using the <code>:server</code> option.</b>
      # @option options [String] :server URL of remote server from which to obtain image.  By default, the image will be obtained from the client's <code>api_endpoint</code>.
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Create container from image specified by alias
      #   Hyperkit.create_container("test-container", alias: "ubuntu/xenial/amd64")
      #
      # @example Create container from image specified by fingerprint
      #   Hyperkit.create_container("test-container",
      #     fingerprint: "097e75d6f7419d3a5e204d8125582f2d7bdd4ee4c35bd324513321c645f0c415")
      #
      # @example Create container from image specified by fingerprint prefix
      #   Hyperkit.create_container("test-container", fingerprint: "097")
      #
      # @example Create container based on most recent match of image properties
      #   Hyperkit.create_container("test-container",
      #     properties: { os: "ubuntu", release: "14.04", architecture: "x86_64" }
      #
      # @example Create an empty container
      #   Hyperkit.create_container("test-container", empty: true)
      #
      # @example Create container with custom configuration.
      #
      #   # Set the MAC address of the container's eth0 device
      #   Hyperkit.create_container("test-container",
      #     alias: "ubuntu/xenial/amd64",
      #     config: {
      #       "volatile.eth0.hwaddr" => "aa:bb:cc:dd:ee:ff"
      #     }
      #   )
      #
      # @example Create container and apply profiles to it
      #   Hyperkit.create_container("test-container",
      #     alias: "ubuntu/xenial/amd64",
      #     profiles: ["migratable", "unconfined"]
      #   )
      #
      # @example Create container from a publicly-accessible remote image
      #   Hyperkit.create_container("test-container",
      #     server: "https://images.linuxcontainers.org:8443",
      #     alias: "ubuntu/xenial/amd64")
      #
      # @example Create container from a private remote image (authenticated by a secret)
      #   Hyperkit.create_container("test-container",
      #     server: "https://private.example.com:8443",
      #     alias: "ubuntu/xenial/amd64",
      #     secret: "shhhhh")
      def create_container(name, options={})

        source = container_source_attribute(options)
        opts = options.except(:sync)

        if ! opts[:empty] && source.empty?
          raise Hyperkit::ImageIdentifierRequired.new("Specify source image by alias, fingerprint, or properties, or create an empty container with 'empty: true'")
        end

        if opts[:empty]
          opts = empty_container_options(name, opts)
        elsif options[:server]
          opts = remote_image_container_options(name, source, opts)
        else
          opts = local_image_container_options(name, source, opts)
        end

        response = post(containers_path, opts).metadata
        handle_async(response, options[:sync])
      end

      # Create a copy of an existing local container.
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param source_name [String] Source container name
      # @param target_name [String] Target container name
      # @param options [Hash] Additional data to be passed
      # @option options [String] :architecture Architecture of the container (e.g. <code>x86_64</code>).  By default, this will be obtained from the image metadata
      # @option options [Hash] :config Container configuration
      # @option options [Boolean] :ephemeral Whether to make the container ephemeral (i.e. delete it when it is stopped; default: <code>false</code>)
      # @option options [Array] :profiles List of profiles to be applied to the container (default: <code>[]</code>)
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Copy container
      #   Hyperkit.copy_container("existing", "new")
      #
      # @example Copy container and override its configuration.
      #
      #   # Set the MAC address of the container's eth0 device
      #   Hyperkit.copy_container("existing", "new", config: {
      #       "volatile.eth0.hwaddr" => "aa:bb:cc:dd:ee:ff"
      #     }
      #   )
      #
      # @example Copy container and apply profiles to it
      #   Hyperkit.copy_container("existing", "new", profiles: ["migratable", "unconfined"])
      #
      # @example Create container from a publicly-accessible remote image
      #   Hyperkit.create_container("test-container",
      #     server: "https://images.linuxcontainers.org:8443",
      #     alias: "ubuntu/xenial/amd64")
      def copy_container(source_name, target_name, options={})

        opts = {
          source: {
            type: "copy",
            source: source_name
          }
        }.merge(extract_container_options(target_name, options))

        response = post(containers_path, opts).metadata
        handle_async(response, options[:sync])

      end

      # @!endgroup

      # @!group Editing

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
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param name [String] Container name
      # @param config [Sawyer::Resource|Hash] Container configuration obtained from #container
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Add 'eth1' device to a container
      #   container = Hyperkit.container("test-container")
      #   container.devices.eth1 = {nictype: "bridged", parent: "lxcbr0", type: "nic"}
      #   Hyperkit.update_container("test-container", container)
      #
      # @example Change container to be ephemeral (i.e. it will be deleted when stopped)
      #   container = Hyperkit.container("test-container")
      #   container.ephemeral = true
      #   Hyperkit.update_container("test-container", container)
      #
      # @example Change container's AppArmor profile to 'unconfined'.
      #   container = Hyperkit.container("test-container")
      #
      #   # Note: due to a bug in Sawyer::Resource, the following will fail
      #   container.config[:"raw.lxc"] = "lxc.aa_profile=unconfined"
      #
      #   # Instead, convert 'config' to a Hash, and update the Hash
      #   container.config = container.config.to_hash
      #   container.config["raw.lxc"] = "lxc.aa_profile=unconfined"
      #
      #   Hyperkit.update_container("test-container", container)
      def update_container(name, config, options={})

        config = config.to_hash
        config[:config] = stringify_hash(config[:config]) if config[:config]

        response = put(container_path(name), config).metadata
        handle_async(response, options[:sync])
      end

      # Rename a container
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param old_name [String] Existing container name
      # @param new_name [String] New container name
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Rename container "test" to "test2"
      #   Hyperkit.rename_container("test", "test2")
      def rename_container(old_name, new_name, options={})
        response = post(container_path(old_name), { name: new_name }).metadata
        handle_async(response, options[:sync])
      end

      # @!endgroup

      # @!group Commands

      # Execute a command in a container
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param container [String] Container name
      # @param command [Array|String] Command to execute
      # @param options [Hash] Additional data to be passed
      # @option options [Hash] :environment Environment variables to set prior to command execution
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Run a command (passed as a string) in container "test-container"
      #   Hyperkit.execute_command("test-container", "echo 'hello world'")
      #
      # @example Run a command (passed as an array) in container "test-container"
      #   Hyperkit.execute_command("test-container",
      #     ["bash", "-c", "echo 'hello world' > /tmp/test.txt"]
      #   )
      #
      # @example Run a command and pass environment variables
      #   Hyperkit.execute_command("test-container",
      #     "/bin/sh -c 'echo \"$MYVAR\" $MYVAR2 > /tmp/test.txt'",
      #     environment: {
      #       MYVAR: "hello world",
      #       MYVAR2: 42
      #     }
      #   )
      def execute_command(container, command, options={})

        opts = options.slice(:environment)
        command = Shellwords.shellsplit(command) if command.is_a?(String)

        opts[:environment] = stringify_hash(opts[:environment]) if opts[:environment]

        response = post(File.join(container_path(container), "exec"), {
          command: command,
          environment: opts[:environment] || {},
          "wait-for-websocket" => false,
          interactive: false
        }).metadata

        handle_async(response, options[:sync])

      end

      alias_method :run_command, :execute_command

      # @!endgroup

      # @!group Deletion

      # Delete a container.  Throws an error if the container is running.
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param name [String] Container name
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Delete container "test"
      #   Hyperkit.delete_container("test")
      #
      def delete_container(name, options={})
        response = delete(container_path(name)).metadata
        handle_async(response, options[:sync])
      end

      # @!endgroup

      # @!group State

      # Retrieve the current state of a container
      #
      # @param name [String] Container name
      # @return [Sawyer::Resource] Container state
      #
      # @example Get container state
      #   Hyperkit.container_state("test-container") #=> {
      #   }
      def container_state(name)
        get(container_state_path(name)).metadata
      end

      # Start a container
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param name [String] Container name
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :stateful Whether to restore previously saved runtime state (default: <code>false</false>)
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @option options [Fixnum] :timeout Time after which the operation is considered to have failed (default: no timeout)
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Start container
      #   Hyperkit.start_container("test")
      #
      # @example Start container and restore previously saved runtime state
      #   # Stop the container and save its runtime state
      #   Hyperkit.stop_container("test", stateful: true)
      #
      #   # Start the container and restore its runtime state
      #   Hyperkit.start_container("test", stateful: true)
      #
      # @example Start container with a timeout
      #   Hyperkit.start_container("test", timeout: 30)
      def start_container(name, options={})
        opts = options.slice(:stateful, :timeout)
        response = put(container_state_path(name), opts.merge(action: "start")).metadata
        handle_async(response, options[:sync])
      end

      # Stop a container
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param name [String] Container name
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :force Whether to force the operation by killing the container
      # @option options [Boolean] :stateful Whether to restore previously saved runtime state (default: <code>false</false>)
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @option options [Fixnum] :timeout Time after which the operation is considered to have failed (default: no timeout)
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Stop container
      #   Hyperkit.stop_container("test")
      #
      # @example Stop container and save its runtime state
      #   # Stop the container and save its runtime state
      #   Hyperkit.stop_container("test", stateful: true)
      #
      #   # Start the container and restore its runtime state
      #   Hyperkit.start_container("test", stateful: true)
      #
      # @example Stop the container forcefully (i.e. kill it)
      #   Hyperkit.stop_container("test", force: true)
      def stop_container(name, options={})
        opts = options.slice(:force, :stateful, :timeout)
        response = put(container_state_path(name), opts.merge(action: "stop")).metadata
        handle_async(response, options[:sync])
      end

      # Restart a running container
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param name [String] Container name
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :force Whether to force the operation by killing the container
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @option options [Fixnum] :timeout Time after which the operation is considered to have failed (default: no timeout)
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Restart container
      #   Hyperkit.restart_container("test")
      #
      # @example Restart container forcefully
      #   Hyperkit.restart_container("test", force: true)
      #
      # @example Restart container with timeout
      #   Hyperkit.restart_container("test", timeout: 30)
      def restart_container(name, options={})
        opts = options.slice(:force, :timeout)
        response = put(container_state_path(name), opts.merge(action: "restart")).metadata
        handle_async(response, options[:sync])
      end

      # Freeze (suspend) a running container
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param name [String] Container name
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @option options [Fixnum] :timeout Time after which the operation is considered to have failed (default: no timeout)
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Suspend container
      #   Hyperkit.freeze_container("test")
      #
      # @example Suspend container with timeout
      #   Hyperkit.freeze_container("test", timeout: 30)
      def freeze_container(name, options={})
        opts = options.slice(:timeout)
        response = put(container_state_path(name), opts.merge(action: "freeze")).metadata
        handle_async(response, options[:sync])
      end

      alias_method :pause_container, :freeze_container
      alias_method :suspend_container, :freeze_container

      # Unfreeze (resume) a frozen container
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param name [String] Container name
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @option options [Fixnum] :timeout Time after which the operation is considered to have failed (default: no timeout)
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Resume container
      #   Hyperkit.unfreeze_container("test")
      #
      # @example Resume container with timeout
      #   Hyperkit.unfreeze_container("test", timeout: 30)
      def unfreeze_container(name, options={})
        opts = options.slice(:timeout)
        response = put(container_state_path(name), opts.merge(action: "unfreeze")).metadata
        handle_async(response, options[:sync])
      end

      alias_method :resume_container, :unfreeze_container

      # @!endgroup

      # @!group Migration

      # Prepare to migrate a container or snapshot.  Generates source data to be passed to {#migrate}.
      #
      # Note that CRIU must be installed on the server to migrate a running container, or LXD will
      # return a 500 error.  On Ubuntu, you can install it with
      # <code>sudo apt-get install criu</code>.
      #
      # @param name [String] Container name
      # @return [Sawyer::Resource] Source data to be passed to {#migrate}
      #
      # @example Retrieve migration source data for container "test"
      #   Hyperkit.init_migration("test") #=> {
      #     :architecture => "x86_64",
      #     :config => {
      #       :"volatile.base_image" => "b41f6b96f103335eafbf38ba65488eda66b05b08b590130e473803631d66ff38",
      #       :"volatile.eth0.hwaddr" => "00:16:3e:e9:d5:5c",
      #       :"volatile.last_state.idmap" =>
      #         "[{\"Isuid\":true,\"Isgid\":false,\"Hostid\":231072,\"Nsid\":0,\"Maprange\":65536},{\"Isuid\":false,\"Isgid\":true,\"Hostid\":231072,\"Nsid\":0,\"Maprange\":65536}]"
      #     },
      #     :profiles => ["default"],
      #     :websocket => {
      #       :url => "https://192.168.103.101:8443/1.0/operations/a30aca8e-8ff3-4437-b1da-bb28b43ee876",
      #       :secrets => {
      #         :control => "a6f8d21ebfe9ec76bf56585c98fd6d700fd43edee513ce61e48e1abeef479106",
      #         :criu => "c8601ec0d07f97f206835dde5783640c08640e9b27e45624d8555546b0cca327",
      #         :fs => "ddf9d064331b9f3728d098873a8a89a7742b8e656f2cd0815f0aee4777ff2b54"
      #       }
      #     },
      #     :certificate => "source server SSL certificate"
      #   }
      #
      # @example Retrieve migration source data for snapshot "snap" of container "test"
      #   Hyperkit.init_migration("test", "snap") #=> {
      #     :architecture => "x86_64",
      #     :config => {
      #       :"volatile.apply_template" => "create",
      #       :"volatile.base_image" => "b41f6b96f103335eafbf38ba65488eda66b05b08b590130e473803631d66ff38",
      #       :"volatile.eth0.hwaddr" => "00:16:3e:e9:d5:5c",
      #       :"volatile.last_state.idmap" =>
      #         "[{\"Isuid\":true,\"Isgid\":false,\"Hostid\":231072,\"Nsid\":0,\"Maprange\":65536},{\"Isuid\":false,\"Isgid\":true,\"Hostid\":231072,\"Nsid\":0,\"Maprange\":65536}]"
      #     },
      #     :profiles => ["default"],
      #     :websocket => {
      #       :url => "https://192.168.103.101:8443/1.0/operations/a30aca8e-8ff3-4437-b1da-bb28b43ee876",
      #       :secrets => {
      #         :control => "a6f8d21ebfe9ec76bf56585c98fd6d700fd43edee513ce61e48e1abeef479106",
      #         :criu => "c8601ec0d07f97f206835dde5783640c08640e9b27e45624d8555546b0cca327",
      #         :fs => "ddf9d064331b9f3728d098873a8a89a7742b8e656f2cd0815f0aee4777ff2b54"
      #       }
      #     },
      #     :certificate => "source server SSL certificate"
      #   }
      def init_migration(container, snapshot=nil)

        if snapshot
          url = snapshot_path(container, snapshot)
          source = snapshot(container, snapshot)
        else
          url = container_path(container)
          source = container(container)
        end

        response = post(url, { migration: true })
        agent = response.agent

        source_data = {
          architecture: source.architecture,
          config: source.config.to_hash,
          profiles: source.profiles,
          websocket: {
            url: File.join(api_endpoint, response.operation),
            secrets: response.metadata.metadata.to_hash,
          },
          certificate: get("/1.0").metadata.environment.certificate,
          snapshot: ! snapshot.nil?
        }

        Sawyer::Resource.new(response.agent, source_data)
      end

      # Migrate a remote container or snapshot to the server
      #
      # Note that CRIU must be installed on the server to migrate a running container, or LXD will
      # return a 500 error.  On Ubuntu, you can install it with
      # <code>sudo apt-get install criu</code>.
      #
      # Also note that, unless overridden with the <code>profiles</code> parameter, if the source
      # container has profiles applied to it that do not exist on the target LXD instance, this
      # method will throw an exception.
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param source [Sawyer::Resource] Source data retrieve from the remote server with {#init_migration}
      # @param dest_name [String] Name of the new container
      # @param options [Hash] Additional data to be passed
      # @option options [String] :architecture Architecture of the container (e.g. <code>x86_64</code>).  By default, this will be obtained from the image metadata
      # @option options [String] :certificate PEM certificate of the source server.  If not specified, defaults to the certificate returned by the source server in the <code>source</code> parameter.
      # @option options [Hash] :config Container configuration
      # @option options [Boolean] :ephemeral Whether to make the container ephemeral (i.e. delete it when it is stopped; default: <code>false</code>)
      # @option options [Boolean] :move Whether the container is being moved (<code>true</code>) or copied (<code>false</code>).  Note that this does not actually delete the container from the remote LXD instance.  Specifying <code>move: true</code> prevents regenerating volatile data (such as a container's MAC addresses), while <code>move: false</code> will regenerate all of this data.  Defaults to <code>false</code> (a copy)
      # @option options [Array] :profiles List of profiles to be applied to the container (default: <code>[]</code>)
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Migrate container from remote instance
      #   remote_lxd = Hyperkit::Client.new(api_endpoint: "remote.example.com")
      #   source_data = remote_lxd.init_migration("remote-container")
      #   Hyperkit.migrate(source_data, "new-container")
      #
      # @example Migrate container and do not regenerate volatile data (e.g. MAC addresses)
      #   remote_lxd = Hyperkit::Client.new(api_endpoint: "remote.example.com")
      #   source_data = remote_lxd.init_migration("remote-container")
      #   Hyperkit.migrate(source_data, "new-container", move: true)
      #
      # @example Migrate container and override its profiles
      #   remote_lxd = Hyperkit::Client.new(api_endpoint: "remote.example.com")
      #   source_data = remote_lxd.init_migration("remote-container")
      #   Hyperkit.migrate(source_data, "new-container", profiles: %w[test-profile1 test-profile2])
      #
      # @example Migrate a snapshot
      #   remote_lxd = Hyperkit::Client.new(api_endpoint: "remote.example.com")
      #   source_data = remote_lxd.init_migration("remote-container", "remote-snapshot")
      #   Hyperkit.migrate(source_data, "new-container", profiles: %w[test-profile1 test-profile2])
      def migrate(source, dest_name, options={})

        opts = {
          name: dest_name,
          architecture: options[:architecture] || source.architecture,
          source: {
            type: "migration",
            mode: "pull",
            operation: source.websocket.url,
            certificate: options[:certificate] || source.certificate,
            secrets: source.websocket.secrets.to_hash
          }
        }

        if ! source.snapshot
          opts["base-image"] = source.config["volatile.base_image"]
          opts[:config] = options[:config] || source.config.to_hash

          # If we're only copying the container, and configuration was explicitly
          # overridden, then remove the volatile entries
          if ! options[:move] && ! options.has_key?(:config)
            opts[:config].delete_if { |k,v| k.to_s.start_with?("volatile") }
          end

        else
          opts[:config] = options[:config] || {}
        end

        if options.has_key?(:profiles)
          opts[:profiles] = options[:profiles]
        else

          dest_profiles = profiles()

          if (source.profiles - dest_profiles).empty?
            opts[:profiles] = source.profiles
          else
            raise Hyperkit::MissingProfiles.new("Not all profiles applied to source container exist on the target LXD instance")
          end

        end

        if options.has_key?(:ephemeral)
          opts[:ephemeral] = options[:ephemeral]
        else
          opts[:ephemeral] = !! source.ephemeral
        end

        response = post(containers_path, opts).metadata
        handle_async(response, options[:sync])
      end

      # @!endgroup

      # @!group Snapshots

      # List of snapshots for a container
      #
      # @param container [String] Container name
      # @return [Array<String>] An array of snapshot names
      #
      # @example Get list of snapshots for container "test"
      #   Hyperkit.snapshots("test") #=> ["snap1", "snap2", "snap3"]
      def snapshots(container)
        response = get snapshots_path(container)
        response.metadata.map { |path| path.split('/').last }
      end

      # Get information on a snapshot
      #
      # @param container [String] Container name
      # @param Snapshot [String] Snapshot name
      # @return [Sawyer::Resource] Snapshot information
      #
      # @example Get information about a snapshot
      #   Hyperkit.snapshot("test-container", "test-snapshot") #=> {
      #     :architecture => "x86_64",
      #     :config => {
      #       :"volatile.apply_template" => "create",
      #       :"volatile.base_image" => "097e75d6f7419d3a5e204d8125582f2d7bdd4ee4c35bd324513321c645f0c415",
      #       :"volatile.eth0.hwaddr" => "00:16:3e:24:5d:7a",
      #       :"volatile.eth0.name" => "eth0",
      #       :"volatile.last_state.idmap" =>
      #         "[{\"Isuid\":true,\"Isgid\":false,\"Hostid\":165536,\"Nsid\":0,\"Maprange\":65536},{\"Isuid\":false,\"Isgid\":true,\"Hostid\":165536,\"Nsid\":0,\"Maprange\":65536}]"
      #     },
      #     :created_at => 2016-03-18 20:55:26 UTC,
      #     :devices => {
      #       :root => {:path => "/", :type => "disk"}
      #     },
      #     :ephemeral => false,
      #     :expanded_config => {
      #       :"volatile.apply_template" => "create",
      #       :"volatile.base_image" => "097e75d6f7419d3a5e204d8125582f2d7bdd4ee4c35bd324513321c645f0c415",
      #       :"volatile.eth0.hwaddr" => "00:16:3e:24:5d:7a",
      #       :"volatile.eth0.name" => "eth0",
      #       :"volatile.last_state.idmap" =>
      #         "[{\"Isuid\":true,\"Isgid\":false,\"Hostid\":165536,\"Nsid\":0,\"Maprange\":65536},{\"Isuid\":false,\"Isgid\":true,\"Hostid\":165536,\"Nsid\":0,\"Maprange\":65536}]"
      #     },
      #     :expanded_devices => {
      #       :eth0 => { :name => "eth0", :nictype => "bridged", :parent => "lxcbr0", :type => "nic"},
      #       :root => { :path => "/", :type => "disk"}
      #     },
      #     :name => "test-container/test-snapshot",
      #     :profiles => ["default"],
      #     :stateful => false
      #   }
      def snapshot(container, snapshot)
        get(snapshot_path(container, snapshot)).metadata
      end

      # Create a snapshot of a container
      #
      # If <code>stateful: true</code> is passed when creating a snapshot of a
      # running container, the container's runtime state will be stored in the
      # snapshot.  Note that CRIU must be installed on the server to create a
      # stateful snapshot, or LXD will return a 500 error.  On Ubuntu, you can
      # install it with
      # <code>sudo apt-get install criu</code>.
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param container [String] Container name
      # @param snapshot [String] Snapshot name
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :stateful Whether to save runtime state for a running container (requires CRIU on the server; default: <code>false</false>)
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Create stateless snapshot for container 'test'
      #   Hyperkit.create_snapshot("test", "snap1")
      #
      # @example Create snapshot and save runtime state for running container 'test'
      #   Hyperkit.create_snapshot("test", "snap1", stateful: true)
      def create_snapshot(container, snapshot, options={})
        opts = options.slice(:stateful)
        opts[:name] = snapshot
        response = post(snapshots_path(container), opts).metadata
        handle_async(response, options[:sync])
      end

      # Delete a snapshot
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param container [String] Container name
      # @param snapshot [String] Snapshot name
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Delete snapshot "snap" from container "test"
      #   Hyperkit.delete_snapshot("test", "snap")
      #
      def delete_snapshot(container, snapshot, options={})
        response = delete(snapshot_path(container, snapshot)).metadata
        handle_async(response, options[:sync])
      end

      # Rename a snapshot
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param container [String] Container name
      # @param old_name [String] Existing snapshot name
      # @param new_name [String] New snapshot name
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Rename snapshot "test/snap1" to "snap2"
      #   Hyperkit.rename_snapshot("test", "snap1", "snap2")
      def rename_snapshot(container, old_name, new_name, options={})
        response = post(snapshot_path(container, old_name), { name: new_name }).metadata
        handle_async(response, options[:sync])
      end

      # Restore a snapshot
      #
      # @async This method is asynchronous.  See {Hyperkit::Configurable#auto_sync} for more information.
      #
      # @param container [String] Container name
      # @param snapshot [String] Name of snapshot to restore
      # @param options [Hash] Additional data to be passed
      # @option options [Boolean] :sync If <code>false</code>, returns an asynchronous operation that must be passed to {Hyperkit::Client::Operations#wait_for_operation}.  If <code>true</code>, automatically waits and returns the result of the operation.  Defaults to value of {Hyperkit::Configurable#auto_sync}.
      # @return [Sawyer::Resource] Operation or result, depending value of <code>:sync</code> parameter and/or {Hyperkit::Client::auto_sync}
      #
      # @example Restore container "test" back to snapshot "snap1"
      #   Hyperkit.restore_snapshot("test", "snap1")
      def restore_snapshot(container, snapshot, options={})
        response = put(container_path(container), { restore: snapshot }).metadata
        handle_async(response, options[:sync])
      end

      alias_method :revert_to_snapshot, :restore_snapshot

      # @!endgroup

      # @!group Files

      # Read the contents of a file in a container
      #
      # @param container [String] Container name
      # @param file [String] Full path to a file within the container
      # @return [String] The contents of the file
      #
      # @example Read the file /etc/hostname in container "test"
      #   Hyperkit.read_file("test", "/etc/hostname") #=> "test-container.example.com"
      def read_file(container, file)
        get(file_path(container, file), url_encode: false)
      end

      # Copy a file from a container to the local system.  The file will be
      # written with the same permissions assigned to it in the container.
      #
      # @param container [String] Container name
      # @param source_file [String] Full path to a file within the container
      # @param dest_file [String] Full path of desired output file (will be created/overwritten)
      # @return [String] Full path to the local output file
      #
      # @example Copy /etc/passwd in container "test" to the local file /tmp/passwd
      #   Hyperkit.pull_file("test", "/etc/passwd", "/tmp/passwd") #=> "/tmp/passwd"
      def pull_file(container, source_file, dest_file)
        contents = get(file_path(container, source_file), url_encode: false)
        headers = last_response.headers

        File.open(dest_file, "wb") do |f|
          f.write(contents)
        end

        if headers["x-lxd-mode"]
          File.chmod(headers["x-lxd-mode"].to_i(8), dest_file)
        end

        dest_file

      end

      # Write to a file in a container
      #
      # @param container [String] Container name
      # @param dest_file [String] Path to the output file in the container
      # @param options [Hash] Additional data to be passed
      # @option options [Fixnum] :uid Owner to assign to the file
      # @option options [Fixnum] :gid Group to assign to the file
      # @option options [Fixnum] :mode File permissions (in octal) to assign to the file
      # @option options [Fixnum] :content Content to write to the file (if no block given)
      # @yieldparam io [StringIO] IO to be used to write to the file from a block
      # @return [Sawyer::Resource]
      #
      # @example Write string "hello" to /tmp/test.txt in container test-container
      #   Hyperkit.write_file("test-container", "/tmp/test.txt", content: "hello")
      #
      # @example Write to file using a block
      #   Hyperkit.write_file("test-container", "/tmp/test.txt") do |io|
      #     io.print "Hello "
      #     io.puts "world"
      #   end
      #
      # @example Assign uid, gid, and mode to a file:
      #   Hyperkit.write_file("test-container",
      #     "/tmp/test.txt",
      #     content: "hello",
      #     uid: 1000,
      #     gid: 1000,
      #     mode: 0644
      #   )
      def write_file(container, dest_file, options={}, &block)

        headers = { "Content-Type" => "application/octet-stream" }
        headers["X-LXD-uid"] = options[:uid].to_s if options[:uid]
        headers["X-LXD-gid"] = options[:gid].to_s if options[:gid]
        headers["X-LXD-mode"] = options[:mode].to_s(8).rjust(4, "0") if options[:mode]

        if ! block_given?
          content = options[:content].to_s
        else
          io = StringIO.new
          yield io
          io.rewind
          content = io.read
        end

        post(file_path(container, dest_file), {
          raw_body: content,
          headers: headers
        })

      end

      # Copy a file from the local system to container
      #
      # @param container [String] Container name
      # @param source_file [String] Full path to a file within the container
      # @param dest_file [String] Full path of desired output file (will be created/overwritten)
      # @param options [Hash] Additional data to be passed
      # @option options [Fixnum] :uid Owner to assign to the file
      # @option options [Fixnum] :gid Group to assign to the file
      # @option options [Fixnum] :mode File permissions (in octal) to assign to the file
      # @return [Sawyer::Resource]
      #
      # @example Copy /tmp/test.txt from the local system to /etc/passwd in the container
      #   Hyperkit.push_file("/tmp/test.txt", "test-container", "/etc/passwd")
      #
      # @example Assign uid, gid, and mode to a file:
      #   Hyperkit.push_file("/tmp/test.txt",
      #     "test-container",
      #     "/etc/passwd",
      #     uid: 1000,
      #     gid: 1000,
      #     mode: 0644
      #   )
      def push_file(source_file, container, dest_file, options={})

        write_file(container, dest_file, options) do |f|
          f.write File.read(source_file)
        end

      end

      # @!endgroup

      # @!group Logs

      # Retrieve a list of logs for a container
      #
      # @param container [String] Container name
      # @return [Array<String>] An array of log filenames
      #
      # @example Get list of logs for container "test-container"
      #   Hyperkit.logs("test-container")
      def logs(container)
        response = get(logs_path(container))
        response.metadata.map { |path| path.sub(logs_path(container) + '/', '') }
      end

      # Retrieve the contents of a log for a container
      #
      # @param container [String] Container name
      # @param log [String] Log filename
      # @return [String] The contents of the log
      #
      # @example Get log "lxc.log" for container "test-container"
      #   Hyperkit.log("test-container", "lxc.log")
      def log(container, log)
        get(log_path(container, log))
      end

      # Delete a container's log
      #
      # @param container [String] Container name
      # @param log [String] Filename of log to delete
      #
      # @example Delete log "lxc.log" for container "test-container"
      #   Hyperkit.delete_log("test-container", "lxc.log")
      def delete_log(container, log)
        delete(log_path(container, log))
      end

      # @!endgroup

      private

      REMOTE_IMAGE_ARGS = [:server, :protocol, :certificate, :secret]

      def log_path(container, log)
        File.join(logs_path(container), log)
      end

      def logs_path(container)
        File.join(container_path(container), "logs")
      end

      def file_path(container, file)
        File.join(container_path(container), "files") + "?path=#{file}"
      end

      def snapshot_path(container, snapshot)
        File.join(snapshots_path(container), snapshot)
      end

      def snapshots_path(name)
        File.join(container_path(name), "snapshots")
      end

      def container_state_path(name)
        File.join(container_path(name), "state")
      end

      def container_path(name)
        File.join(containers_path, name)
      end

      def containers_path
        "/1.0/containers"
      end

      def extract_container_options(name, options)
        opts = options.slice(:architecture, :profiles, :ephemeral, :config).
                       merge({ name: name })

        opts[:config] = stringify_hash(opts[:config]) if opts[:config]

        opts
      end

      def container_source_attribute(options)

        [:fingerprint, :alias, :properties].each do |attr|
          return options.slice(attr) if options[attr]
        end

        {}

      end

      def empty_container_options(name, options)
        opts = {
          source: {
            type: "none"
          }
        }.merge(extract_container_options(name, options))

        [:alias, :certificate, :fingerprint, :properties, :protocol, :secret, :server].each do |prop|
          if ! (options.keys & [prop]).empty?
            raise Hyperkit::InvalidImageAttributes.new("empty: true is not compatible with the #{prop} option")
          end
        end

        opts

      end


      def remote_image_container_options(name, source, options)

        opts = {
          source: {
            type: "image",
            mode: "pull"
          }.merge(options.slice(*REMOTE_IMAGE_ARGS)).merge(source)

        }.merge(extract_container_options(name, options))

        if options[:protocol] && ! %w[lxd simplestreams].include?(options[:protocol])
          raise Hyperkit::InvalidProtocol.new("Invalid protocol.  Valid choices: lxd, simplestreams")
        end

        opts

      end

      def local_image_container_options(name, source, options)

        opts = {
          source: {
            type: "image"
          }.merge(source)
        }.merge(extract_container_options(name, options))

        if ! (options.keys & REMOTE_IMAGE_ARGS).empty?
          raise Hyperkit::InvalidImageAttributes.new(":protocol, :certificate, and :secret only apply when :server is also passed")
        end

        opts

      end

    end

  end

end
