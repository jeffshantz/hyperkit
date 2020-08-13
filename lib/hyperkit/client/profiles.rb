require 'active_support/core_ext/hash/except'

module Hyperkit

  class Client

    # Methods for the profiles API
    #
    # @see Hyperkit::Client
    # @see https://github.com/lxc/lxd/blob/master/doc/rest-api.md
    module Profiles

      # List of profiles on the server
      #
      # @return [Array<String>] An array of profile names
      #
      # @example Get list of profiles
      #   Hyperkit.profiles #=> ["default", "docker"]
      def profiles
        response = get(profiles_path)
        response.metadata.map { |path| path.split('/').last }
      end

      # Create a profile
      #
      # @param name [String] Profile name
      # @param options [Hash] Additional data to be passed
      # @option options [Hash] :config Profile configuration
      # @option options [String] :description Profile description
      # @option options [Hash] :devices Profile devices
      # @return [Sawyer::Resource]
      #
      # @example Create profile with config
      #   Hyperkit.create_profile("test-profile", config: {
      #     "limits.memory" => "2GB",
      #     "limits.cpu" => 2,
      #     "raw.lxc" => "lxc.aa_profile = unconfined"
      #   })
      #
      # @example Create profile with devices
      #   Hyperkit.create_profile("test-profile", devices: {
      #     eth0: {
      #       nictype: "bridged",
      #       parent: "br-ext",
      #       type: "nic"
      #     }
      #   })
      def create_profile(name, options={})
        opts = options.merge(name: name)
        opts[:config] = stringify_hash(opts[:config]) if opts[:config]
        post(profiles_path, opts).metadata
      end

      # Retrieve a profile
      #
      # @param name [String] Profile name
      # @return [Sawyer::Resource] Profile
      #
      # @example Retrieve profile 'test-profile'
      #   Hyperkit.profile("test-profile")
      def profile(name)
        get(profile_path(name)).metadata
      end

      # Update an existing profile
      #
      # @param name [String] Profile name
      # @param options [Hash] Additional data to be passed
      # @option options [Hash] :config Profile configuration.  Existing configuration will be overwritten.
      # @option options [String] :description Profile description
      # @option options [Hash] :devices Profile devices.  Existing devices will be overwritten.
      # @return [Sawyer::Resource]
      #
      # @example Update profile with config (config is overwritten -- not merged)
      #   Hyperkit.update_profile("test-profile", config: {
      #     "limits.memory" => "4GB",
      #     "limits.cpu" => 4,
      #     "raw.lxc" => "lxc.aa_profile = unconfined"
      #   })
      #
      # @example Create profile with devices (devices are overwritten -- not merged)
      #   Hyperkit.create_profile("test-profile", devices: {
      #     eth0: {
      #       nictype: "bridged",
      #       parent: "br-int",
      #       type: "nic"
      #     }
      #   })
      def update_profile(name, options={})
        opts = options.except(:name)
        opts[:config] = stringify_hash(opts[:config]) if opts[:config]
        put(profile_path(name), opts).metadata
      end

      # Patch an existing profile using patch api
      #
      # @param name [String] Profile name
      # @param options [Hash] Additional data to be passed
      # @option options [Hash] :config Profile configuration. It will be merged with existing configuration
      # @option options [String] :description Profile description
      # @option options [Hash] :devices Profile devices.  Existing devices will be merged
      # @return [Sawyer::Resource]
      #
      # @example Patch profile with config (config is merged)
      #   Hyperkit.patch_profile("test-profile", config: {
      #     "limits.memory" => "4GB",
      #     "limits.cpu" => 4,
      #     "raw.lxc" => "lxc.aa_profile = unconfined"
      #   })
      #
      def patch_profile(name, options={})
        opts = options.except(:name)
        opts[:config] = stringify_hash(opts[:config]) if opts[:config]
        patch(profile_path(name), opts).metadata
      end

      # Rename a profile
      #
      # @param old_name [String] Existing profile name
      # @param new_name [String] New profile name
      # @return [Sawyer::Resource]
      #
      # @example Rename profile 'test' to 'test2'
      #   Hyperkit.rename_profile("test", "test2")
      def rename_profile(old_name, new_name)
        post(profile_path(old_name), { name: new_name }).metadata
      end

      # Delete a profile
      #
      # @param name [String] Profile name
      # @return [Sawyer::Resource]
      #
      # @example Delete profile 'test-profile'
      #   Hyperkit.delete_profile("test-profile")
      def delete_profile(name)
        delete(profile_path(name)).metadata
      end

      private

      def profiles_path
        "/1.0/profiles"
      end

      def profile_path(name)
        File.join(profiles_path, name)
      end

    end

  end

end
