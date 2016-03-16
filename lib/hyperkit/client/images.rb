module Hyperkit

  class Client

    # Methods for the images API
    # 
    # @see https://github.com/lxc/lxd/blob/master/specs/rest-api.md
    module Images

      # List of images on the server (public or private)
      #
      # @return [Array<String>] An array of image fingerprints
      # @example Get list of images 
      #   Hyperkit.client.images #=> ["54c8caac1f61901ed86c68f24af5f5d3672bdc62c71d04f06df3a59e95684473",
      #                               "97d97a3d1d053840ca19c86cdd0596cf1be060c5157d31407f2a4f9f350c78cc"]
      def images 
        response = get images_path 
        response[:metadata].map { |path| path.split('/').last }
      end

      # Get information on an image
      #
      # @return [Hash] A hash of information about the image
      # @example Get information about an image on images.linuxcontainers.org
      #   Hyperkit.client.api_endpoint = "https://images.linuxcontainers.org:8443"
      #   Hyperkit.client.image("45bcc353f629b23ce30ef4cca14d2a4990c396d85ea68905795cc7579c145123") #=> {
      #     :properties=>{:description=>"Centos 6 (amd64) (20160314_02:16)"},
      #     :expires_at=>1970-01-01 00:00:00 UTC,
      #     :filename=>"centos-6-amd64-default-20160314_02:16.tar.xz",
      #     :uploaded_at=>2016-03-15 01:20:10 UTC,
      #     :size=>54717798,
      #     :public=>true,
      #     :architecture=>"x86_64",
      #     :aliases=>[],
      #     :created_at=>2016-03-15 01:20:10 UTC,
      #     :fingerprint=> "45bcc353f629b23ce30ef4cca14d2a4990c396d85ea68905795cc7579c145123"
      #   }
      def image(fingerprint)
        response = get image_path(fingerprint)
        response[:metadata]
      end
 
      # List of image aliases on the server (public or private)
      #
      # @return [Array<String>] An array of image aliases
      # @example Get list of image aliases
      #   Hyperkit.client.images #=> [
      #     "ubuntu/xenial/amd64/default",
      #     "ubuntu/xenial/amd64",
      #     "ubuntu/xenial/armhf/default",
      #     "ubuntu/xenial/armhf",
      #     "ubuntu/xenial/i386/default",
      #     "ubuntu/xenial/i386",
      #     "ubuntu/xenial/powerpc/default",
      #     "ubuntu/xenial/powerpc",
      #     "ubuntu/xenial/ppc64el/default",
      #     "ubuntu/xenial/ppc64el",
      #     "ubuntu/xenial/s390x/default",
      #     "ubuntu/xenial/s390x"
      #   ] 
      def image_aliases
        response = get image_aliases_path 
        response[:metadata].map { |path| path.sub("#{image_aliases_path}/","") }
      end

      private

      def image_path(fingerprint)
        File.join(images_path, fingerprint)
      end

      def image_aliases_path
        File.join(images_path, "aliases")
      end

      def images_path
        "/1.0/images"
      end
 
    end

  end

end


