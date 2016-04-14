require 'active_support/core_ext/hash/except'

module Hyperkit

  class Client

    # Methods for the profiles API
    module Profiles

      # GET /profiles
      def profiles
        response = get(profiles_path)
        response.metadata.map { |path| path.split('/').last }
      end

      # POST /profiles
      def create_profile(name, options={})
        options = options.merge(name: name)
        post(profiles_path, options).metadata
      end

      # GET /profiles/<name>
      def profile(name)
        get(profile_path(name)).metadata
      end

      # PUT /profiles/<name>
      def update_profile(name, options={})
        put(profile_path(name), options.except(:name)).metadata
      end

      # POST /profiles/<name>
      def rename_profile(old_name, new_name)
        post(profile_path(old_name), { name: new_name }).metadata
      end

      # DELETE /profiles/<name>
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
