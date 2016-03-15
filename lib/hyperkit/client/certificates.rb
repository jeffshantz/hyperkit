module Hyperkit

  class Client

    # Methods for the certificates API
    module Certificates

      # GET /certificates
      def certificates 
        response = get certificates_path 
        response[:metadata].map { |path| path.split('/').last }
      end

      def certificates_path
        "/1.0/certificates"
      end
    end

  end

end

