module Hyperkit

  class Client

    # Methods for the containers API
    # 
    # @see https://github.com/lxc/lxd/blob/master/specs/rest-api.md
    module Containers

      REMOTE_IMAGE_ARGS = [:server, :protocol, :certificate, :secret]

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

      # Create a container from an image (local or remote).  The container will
      # be created in the <code>Stopped</code> state.
      #
      # @param name [String] Container name
      # @param options [Hash] Additional data to be passed
      # @option options [String] :alias Alias of the source image.  <b>Either <code>:alias</code>, <code>:fingerprint</code>, <code>:properties</code>, or <code>empty: true</code> must be specified</b>.
      # @option options [String] :architecture Architecture of the container (e.g. <code>x86_64</code>).  By default, this will be obtained from the image metadata
      # @option options [String] :certificate PEM certificate to use to authenticate with the remote server. If not specified, and the source image is private, the target LXD server's certificate is used for authentication.  <b>This option is valid only when transferring an image from a remote server using the <code>:server</code> option.</b>
      # @option options [Hash] :config Container configuration
      # @option options [Boolean] :ephemeral Whether to make the image ephemeral (i.e. delete it when it is stopped; default: <code>false</code>)
      # @option options [Boolean] :empty Whether to make an empty container (i.e. not from an image).  Specifying <code>true</code> will cause LXD to create a container with no rootfs.  That is, /var/lib/lxd/<container-name> will simply be an empty directly.  One can then create a rootfs directory within this directory and populate it manually.  This is useful when migrating LXC containers to LXD.
      # @option options [String] :fingerprint SHA-256 fingerprint of the source image.  <b>Either <code>:alias</code>, <code>:fingerprint</code>, <code>:properties</code>, or <code>empty: true</code> must be specified</b>.
      # @option options [Array] :profiles List of profiles to be applied to the container (default: <code>[]</code>)
      # @option options [String] :properties Properties of the source image.  <b>Either <code>:alias</code>, <code>:fingerprint</code>, <code>:properties</code>, or <code>empty: true</code> must be specified</b>.
      # @option options [String] :protocol Protocol to use in transferring the image (<code>lxd</code> or <code>simplestreams</code>; defaults to <code>lxd</code>).  <b>This option is valid only when transferring an image from a remote server using the <code>:server</code> option.</b>
      # @option options [String] :secret Secret to use to retrieve the image.  <b>This option is valid only when transferring an image from a remote server using the <code>:server</code> option.</b>
      # @option options [String] :server URL of remote server from which to obtain image.  By default, the image will be obtained from the client's <code>api_endpoint</code>.
      #
      # @example Create container from image specified by alias
      #   Hyperkit.client.create_container("test-container", alias: "ubuntu/xenial/amd64")
      #
      # @example Create container from image specified by fingerprint
      #   Hyperkit.client.create_container("test-container",
      #     fingerprint: "097e75d6f7419d3a5e204d8125582f2d7bdd4ee4c35bd324513321c645f0c415")
      #
      # @example Create container based on most recent match of image properties
      #   Hyperkit.client.create_container("test-container",
      #     properties: { os: "ubuntu", release: "14.04", architecture: "x86_64" }
      #
      # @example Create an empty container
      #   Hyperkit.client.create_container("test-container", empty: true)
      #
      # @example Create container with custom configuration.
      #
      #   # Set the MAC address of the container's eth0 device
      #   Hyperkit.client.create_container("test-container",
      #     alias: "ubuntu/xenial/amd64",
      #     config: {
      #       "volatile.eth0.hwaddr" => "aa:bb:cc:dd:ee:ff"
      #     }
      #   )
      #
      # @example Create container and apply profiles to it
      #   Hyperkit.client.create_container("test-container",
      #     alias: "ubuntu/xenial/amd64",
      #     profiles: ["migratable", "unconfined"]
      #   )
      #
      # @example Create container from a publicly-accessible remote image
      #   Hyperkit.client.create_container("test-container",
      #     server: "https://images.linuxcontainers.org:8443",
      #     alias: "ubuntu/xenial/amd64")
      #
      # @example Create container from a private remote image (authenticated by a secret)
      #   Hyperkit.client.create_container("test-container",
      #     server: "https://private.example.com:8443",
      #     alias: "ubuntu/xenial/amd64",
      #     secret: "shhhhh")
      def create_container(name, options={})

        source = container_source_attribute(options)

        if ! options[:empty] && source.empty?
          raise Hyperkit::ImageIdentifierRequired.new("Specify source image by alias, fingerprint, or properties, or create an empty container with 'empty: true'")
        end

        if options[:empty]
          opts = empty_container_options(name, options)
        elsif options[:server]
          opts = remote_image_container_options(name, source, options)
        else
          opts = local_image_container_options(name, source, options)
        end

        post(containers_path, opts).metadata
      
      end

      # Create a copy of an existing local container.
      #
      # @param source_name [String] Source container name
      # @param target_name [String] Target container name
      # @param options [Hash] Additional data to be passed
      # @option options [String] :architecture Architecture of the container (e.g. <code>x86_64</code>).  By default, this will be obtained from the image metadata
      # @option options [Hash] :config Container configuration
      # @option options [Boolean] :ephemeral Whether to make the image ephemeral (i.e. delete it when it is stopped; default: <code>false</code>)
      # @option options [Array] :profiles List of profiles to be applied to the container (default: <code>[]</code>)
      #
      # @example Copy container
      #   Hyperkit.client.copy_container("existing", "new")
      #
      # @example Copy container and override its configuration.
      #
      #   # Set the MAC address of the container's eth0 device
      #   Hyperkit.client.copy_container("existing", "new", config: {
      #       "volatile.eth0.hwaddr" => "aa:bb:cc:dd:ee:ff"
      #     }
      #   )
      #
      # @example Copy container and apply profiles to it
      #   Hyperkit.client.copy_container("existing", "new", profiles: ["migratable", "unconfined"])
      #
      # @example Create container from a publicly-accessible remote image
      #   Hyperkit.client.create_container("test-container",
      #     server: "https://images.linuxcontainers.org:8443",
      #     alias: "ubuntu/xenial/amd64")
      def copy_container(source_name, target_name, options={})

        opts = {
          source: {
            type: "copy",
            source: source_name
          }
        }.merge(extract_container_options(target_name, options))

        post(containers_path, opts).metadata
      
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
      def update_container(name, config)

        config = config.to_hash
 
        # Stringify values in the config hash, since LXD chokes on non-String values
        if config[:config]
          config[:config] = config[:config].inject({}){|h,(k,v)| h[k.to_s] = v.to_s; h}
        end

        put(container_path(name), config).metadata
      end

      # Rename a container.
      #
      # @param old_name [String] Existing container name
      # @param new_name [String] New container name
      #
      # @example Rename container "test" to "test2"
      #   Hyperkit.client.rename_container("test", "test2")
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

      alias_method :resume_container, :unfreeze_container

      # Prepare to migrate a container.  Generates source data to be passed to #migrate_container.
      #
      # Note that CRIU must be installed on the server to migrate a running container, or LXD will
      # return a 500 error.  On Ubuntu, you can install it with 
      # <code>sudo apt-get install criu</code>.
      #
      # @param name [String] Container name
      # @example Retrieve migration source data for container "test"
      #   Hyperkit.client.init_container_migration("test") #=> {
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
      def init_container_migration(name)
        response = post(container_path(name), { "migration": true })
        agent = response.agent

        source_container = container(name)
        
        source = {
          architecture: source_container.architecture,
          config: source_container.config.to_hash,
          profiles: source_container.profiles,
          websocket: {
            url: File.join(api_endpoint, response.operation),
            secrets: response.metadata.metadata.to_hash,
          },
          certificate: get("/1.0").metadata.environment.certificate
        }

        Sawyer::Resource.new(response.agent, source)
      end

      # Migrate a remote container to the server.  
      #
      # Note that CRIU must be installed on the server to migrate a running container, or LXD will
      # return a 500 error.  On Ubuntu, you can install it with 
      # <code>sudo apt-get install criu</code>.
      #
      # Also note that, unless overridden with the <code>profiles</code> parameter, if the source
      # container has profiles applied to it that do not exist on the target LXD instance, this
      # method will throw an exception.
      #
      # @param source [Sawyer::Resource] Source data retrieve from the remote server with #init_container_migration
      # @param dest_name [String] Name of the new container
      # @param options [Hash] Additional data to be passed
      # @option options [String] :architecture Architecture of the container (e.g. <code>x86_64</code>).  By default, this will be obtained from the image metadata
      # @option options [String] :certificate PEM certificate of the source server.  If not specified, defaults to the certificate returned by the source server in the <code>source</code> parameter.
      # @option options [Hash] :config Container configuration
      # @option options [Boolean] :ephemeral Whether to make the image ephemeral (i.e. delete it when it is stopped; default: <code>false</code>)
      # @option options [Boolean] :move Whether the container is being moved (<code>true</code>) or copied (<code>false</code>).  Note that this does not actually delete the container from the remote LXD instance.  Specifying <code>move: true</code> prevents regenerating volatile data (such as a container's MAC addresses), while <code>move: false</code> will regenerate all of this data.  Defaults to <code>false</code> (a copy)
      # @option options [Array] :profiles List of profiles to be applied to the container (default: <code>[]</code>)
      #
      # @example Migrate container from remote instance
      #   remote_lxd = Hyperkit::Client.new(api_endpoint: "remote.example.com")
      #   source_data = remote_lxd.init_container_migration("remote-container")
      #   Hyperkit.client.migrate_container(source_data, "new-container")
      #
      # @example Migrate container and do not regenerate volatile data (e.g. MAC addresses)
      #   remote_lxd = Hyperkit::Client.new(api_endpoint: "remote.example.com")
      #   source_data = remote_lxd.init_container_migration("remote-container")
      #   Hyperkit.client.migrate_container(source_data, "new-container", move: true)
      #
      # @example Migrate container and override its profiles
      #   remote_lxd = Hyperkit::Client.new(api_endpoint: "remote.example.com")
      #   source_data = remote_lxd.init_container_migration("remote-container")
      #   Hyperkit.client.migrate_container(source_data, "new-container", profiles: %w[test-profile1 test-profile2])
      def migrate_container(source, dest_name, options={})

        opts = {
          name: dest_name,
          architecture: options[:architecture] || source.architecture,
          config: options[:config] || source.config.to_hash,
          source: {
            type: "migration",
            mode: "pull",
            operation: source.websocket.url,
            certificate: options[:certificate] || source.certificate,
            secrets: source.websocket.secrets.to_hash
          }
        }

        #TODO: Handle this when snapshots are implemented
        #if ! (source is a snapshot)
          opts["base-image"] = source.config["volatile.base_image"]

          # If we're only copying the container, and configuration was explicitly 
          # overridden, then remove the volatile entries
          if ! options[:move] && ! options.has_key?(:config)
            opts[:config].delete_if { |k,v| k.to_s.start_with?("volatile") }
          end

        #end

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

        post(containers_path, opts).metadata
      end

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

      def extract_container_options(name, options)
        opts = options.slice(:architecture, :profiles, :ephemeral, :config).
                       merge({ name: name })
      
        # Stringify any config values since LXD croaks on non-String values
        if opts[:config]
          opts[:config] = opts[:config].inject({}){|h,(k,v)| h[k.to_s] = v.to_s; h}
        end

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
