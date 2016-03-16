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

      private

      def images_path
        "/1.0/images"
      end
 
    end

  end

end


