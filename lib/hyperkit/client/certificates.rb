require 'active_support/core_ext/hash/slice'
require 'base64'

module Hyperkit

  class Client

    # Methods for the certificates API
    # 
    # @see Hyperkit::Client
    # @see https://github.com/lxc/lxd/blob/master/specs/rest-api.md
    module Certificates

      # List of trusted certificates on the server
      #
      # @return [Array<String>] An array of certificate fingerprints
      #
      # @example Get list of containers
      #   Hyperkit.certificates #=> [
      #     "c782c0f3530a04a5b2b78fc5292b7500aef1299370288b5eeb0450a6613a2c82",
      #     "b7720e1eb839056158cf65d182865491a0403f766983b95f5098d05911bbff89"
      #   ]
      def certificates 
        response = get(certificates_path)
        response.metadata.map { |path| path.split('/').last }
      end

      # Add a new trusted certificate to the server
      #
      # @param cert [String] Certificate contents in PEM format
      # @param options [Hash] Additional data to be passed
      # @option options [String] :name Optional name for the certificate.  If not specified, the host in the TLS header for the request is used.
      # @option options [String] :password The trust password for that server.  Only required if untrusted. 
      # @return [Sawyer::Resource]
      #
      # @example Add trusted certificate
      #   Hyperkit.create_certificate(File.read("/tmp/cert.pem"))
      #
      # @example Add trusted certificate via untrusted client connection
      #   Hyperkit.create_certificate(File.read("/tmp/cert.pem"), password: "server-trust-password")
      def create_certificate(cert, options={})
        options = options.slice(:name, :password)
        options = options.merge(type: "client", certificate: Base64.strict_encode64(OpenSSL::X509::Certificate.new(cert).to_der))
        post(certificates_path, options).metadata
      end

      # Retrieve a trusted certificate from the server
      #
      # @param fingerprint [String] Fingerprint of the certificate to retrieve.  Can be a prefix, as long as it is unambigous
      # @return [Sawyer::Resource] Certificate information
      # 
      # @example Retrieve a certificate
      #   Hyperkit.certificate("c782c0f3530a04a5b2b78fc5292b7500aef1299370288b5eeb0450a6613a2c82") #=> {
      #     :certificate => "-----BEGIN CERTIFICATE-----\nMIIEW...ceyg04=\n-----END CERTIFICATE-----\n", 
      #     :fingerprint => "c782c0f3530a04a5b2b78fc5292b7500aef1299370288b5eeb0450a6613a2c82", 
      #     :type => "client"   
      #   }
      #
      # @example Retrieve a certificate by specifying a prefix of its fingerprint
      #   Hyperkit.certificate("c7") #=> {
      #     :certificate => "-----BEGIN CERTIFICATE-----\nMIIEW...ceyg04=\n-----END CERTIFICATE-----\n", 
      #     :fingerprint => "c782c0f3530a04a5b2b78fc5292b7500aef1299370288b5eeb0450a6613a2c82", 
      #     :type => "client"   
      #   }
      #
      # @todo Write tests for the prefix
      def certificate(fingerprint)
        get(certificate_path(fingerprint)).metadata
      end

      # Delete a trusted certificate from the server
      #
      # @param fingerprint [String] Fingerprint of the certificate to retrieve.  Can be a prefix, as long as it is unambigous
      # @return [Sawyer::Resource]
      #
      # @example Delete a certificate
      #   Hyperkit.delete_certificate("c782c0f3530a04a5b2b78fc5292b7500aef1299370288b5eeb0450a6613a2c82")
      #
      # @example Delete a certificate by specifying a prefix of its fingerprint
      #   Hyperkit.delete_certificate("c7")
      #
      # @todo Write tests for the prefix
      def delete_certificate(fingerprint)
        delete(certificate_path(fingerprint)).metadata
      end

      private

      def certificate_path(fingerprint)
        File.join(certificates_path, fingerprint)
      end

      def certificates_path
        "/1.0/certificates"
      end

    end

  end

end

