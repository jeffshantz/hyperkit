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

      # Get information on an image by its fingerprint
      #
      # @param fingerprint [String] The image's fingerprint
      # @return [Hash] A hash of information about the image
      #
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

      # Get information on an image by one of its aliases
      #
      # @param alias_name [String] An alias of the image
      # @return [Hash] A hash of information about the image
      #
      # @example Get information about an image on images.linuxcontainers.org
      #   Hyperkit.client.api_endpoint = "https://images.linuxcontainers.org:8443"
      #   Hyperkit.client.image_by_alias("ubuntu/xenial/amd64") #=> {
      #     :fingerprint=> "878cf0c70e14fec80aaf4d5e923670e68c45aa89fb05a481019bf086aec42649",
      #     :expires_at=>1970-01-01 00:00:00 UTC,
      #     :size=>88239818,
      #     :architecture=>"x86_64",
      #     :created_at=>2016-03-16 04:53:46 UTC,
      #     :filename=>"ubuntu-xenial-amd64-default-20160316_03:49.tar.xz",
      #     :uploaded_at=>2016-03-16 04:53:46 UTC,
      #     :aliases=>
      #       [{:name=>"ubuntu/xenial/amd64/default",
      #         :target=>"ubuntu/xenial/amd64/default",
      #         :description=>"Ubuntu xenial (amd64) (default)"},
      #        {:name=>"ubuntu/xenial/amd64",
      #         :target=>"ubuntu/xenial/amd64",
      #         :description=>"Ubuntu xenial (amd64)"}],
      #     :properties=>{:description=>"Ubuntu xenial (amd64) (20160316_03:49)"},
      #     :public=>true}
      #   }
      def image_by_alias(alias_name)
        a = image_alias(alias_name)
        image(a[:target])
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

      # Get information on an image alias
      #
      # @param alias_name [String] An image alias
      # @return [Hash] A hash of information about alias
      #
      # @example Get information about an alias on images.linuxcontainers.org
      #   Hyperkit.client.api_endpoint = "https://images.linuxcontainers.org:8443"
      #   Hyperkit.client.image_alias("ubuntu/xenial/amd64/default") #=> {
      #     :name=>"ubuntu/xenial/amd64/default",
      #     :target=>"878cf0c70e14fec80aaf4d5e923670e68c45aa89fb05a481019bf086aec42649"
      #   }
      def image_alias(alias_name)
        response = get image_alias_path(alias_name)
        response[:metadata]
      end
 
      # Assign an alias for an image
      #
      # @param fingerprint [String] Fingerprint of the image
      # @param alias_name [String] Alias to assign to the image
      # @param options [Hash] Additional data to be passed
      # @option options [String] :description Alias description
      #
      # @example Assign alias "ubuntu/xenial/amd64" to an image
      #   Hyperkit.client.create_image_alias(
      #     "878cf0c70e14fec80aaf4d5e923670e68c45aa89fb05a481019bf086aec42649",
      #     "ubuntu/xenial/amd64")
      # @example Assign alias "ubuntu/xenial/amd64" with a description
      #   Hyperkit.client.create_image_alias(
      #     "878cf0c70e14fec80aaf4d5e923670e68c45aa89fb05a481019bf086aec42649",
      #     "ubuntu/xenial/amd64",
      #     description: "Ubuntu Xenial amd64")
      def create_image_alias(fingerprint, alias_name, options={})
        response = post image_aliases_path, options.slice(:description).merge(
          {
            target: fingerprint,
            name: alias_name
          }
        )
        response[:metadata]
      end

      # Delete an alias for an image
      #
      # @param alias_name [String] Alias to delete
      #
      # @example Delete alias "ubuntu/xenial/amd64"
      #   Hyperkit.client.delete_image_alias("ubuntu/xenial/amd64")
      def delete_image_alias(alias_name)
        response = delete image_alias_path(alias_name)
        response[:metadata]
      end

      # Rename an image alias
      #
      # @param old_alias [String] Alias to rename
      # @param new_alias [String] New alias
      #
      # @example Rename alias "ubuntu/xenial/amd64" to "ubuntu/xenial/default"
      #   Hyperkit.client.rename_image_alias("ubuntu/xenial/amd64", "ubuntu/xenial/default")
      def rename_image_alias(old_alias, new_alias)
        response = post image_alias_path(old_alias), { name: new_alias }
        response[:metadata]
      end

      # Update an image alias
      #
      # @param alias_name [String] Alias to update
      # @param options [Hash] Additional data to be passed
      # @option options [String] :target Image fingerprint
      # @option options [String] :description Alias description
      #
      # @example Update alias "ubuntu/xenial/amd64" to point to image "097..."
      #   Hyperkit.client.update_image_alias("ubuntu/xenial/amd64",
      #     target: "097e75d6f7419d3a5e204d8125582f2d7bdd4ee4c35bd324513321c645f0c415")
      #
      # @example Update alias "ubuntu/xenial/amd64" with a new description
      #   Hyperkit.client.update_image_alias("ubuntu/xenial/amd64", description: "Ubuntu 16.04")
      def update_image_alias(alias_name, options={})

        options = options.slice(:description, :target)

        if options.empty?
          raise Hyperkit::AliasAttributesRequired.new("At least one of :target or :description required")
        end

        response = put image_alias_path(alias_name), options
        response[:metadata]
      end

      # Upload an image from a local file
      #
      # @param file [String] Path of image tarball to be uploaded
      # @param options [Hash] Additional data to be passed
      # @option options [String] :fingerprint SHA-256 fingerprint of the tarball. If the fingerprint of the uploaded image does not match, the image will not be saved on the server.
      # @option options [String] :filename Tarball filename to store with the image on the server and used when exporting the image (default: name of file being uploaded).
      # @option options [Boolean] :public Whether or not the image should be publicly-accessible by unauthenticated users (default: false).
      # @option options [Hash] :properties Hash of additional properties to store with the image
      #
      # @example Upload a private image
      #   Hyperkit.client.create_image_from_file("/tmp/ubuntu-14.04-amd64-lxc.tar.gz")
      #
      # @example Upload a public image
      #   Hyperkit.client.create_image_from_file("/tmp/ubuntu-14.04-amd64-lxc.tar.gz", public: true)
      #
      # @example Store properties with the uploaded image, and override its filename
      #   Hyperkit.client.create_image_from_file("/tmp/ubuntu-14.04-amd64-lxc.tar.gz",
      #     filename: "ubuntu-trusty.tar.gz",
      #     properties: {
      #       os: "ubuntu"
      #       codename: "trusty"
      #       version: "14.04"
      #     }
      #   )
      #
      # @example Upload an image, but only store it if the uploaded file has the same fingerprint
      #   Hyperkit.client.create_image_from_file("/tmp/ubuntu-14.04-amd64-lxc.tar.gz",
      #     fingerprint: "3dc37b8185cc811bcad5e319a9f38daeae823065dd6264334ac07b8324a42f2d")
      def create_image_from_file(file, options={})
        headers = { "Content-Type" => "application/octet-stream" }

        headers["X-LXD-fingerprint"] = options[:fingerprint] if options[:fingerprint]
        headers["X-LXD-filename"] = options[:filename] || File.basename(file)
        headers["X-LXD-public"] = 1.to_s if options[:public]

        if options[:properties]
          properties = options[:properties].map do |k,v|
            "#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}"
          end
          headers["X-LXD-properties"] = properties.join("&")
        end

        response = post images_path, {
          raw_body: File.read(file),
          headers: headers
        }
        response[:metadata]
      end

      # Import an image from a remote server
      #
      # @param server [String] Source server
      # @param options [Hash] Additional data to be passed
      # @option options [String] :alias Alias of the source image to import.  <b>Either <code>:alias</code> or <code>:fingerprint</code> must be specified</b>.
      # @option options [Boolean] :auto_update Whether or not the image should be automatically updated from the source server (source image must be public and must be referenced by alias -- not fingerprint; default: <code>false</code>).
      # @option options [String] :certificate PEM certificate to use to authenticate with the source server. If not specified, and the source image is private, the target LXD server's certificate is used for authentication.
      # @option options [String] :filename Tarball filename to store with the image on the server and used when exporting the image (default: filename retrieved from the source server).
      # @option options [String] :fingerprint SHA-256 fingerprint of the source image to import.  <b>Either <code>:alias</code> or <code>:fingerprint</code> must be specified</b>.
      # @option options [String] :protocol Protocol to use in transferring the image (<code>lxd</code> or <code>simplestreams</code>; defaults to <code>lxd</code>)
      # @option options [Boolean] :public Whether or not the image should be publicly-accessible by unauthenticated users (default: <code>false</code>).
      # @option options [Hash] :properties Hash of additional properties to store with the image
      # @option options [String] :secret Secret to use to retrieve the image
      #
      # @example Import image by alias
      #   Hyperkit.client.create_image_from_remote("https://images.linuxcontainers.org:8443", 
      #     alias: "ubuntu/xenial/amd64")
      #     
      # @example Import image by fingerprint
      #   Hyperkit.client.create_image_from_remote("https://images.linuxcontainers.org:8443", 
      #     fingerprint: "b1cf3d836196c316897d39872ff25e2d912ea933207b0c591334a67b290a5f1b")
      #
      # @example Import image and automatically update it when it is updated on the remote server
      #   Hyperkit.client.create_image_from_remote("https://images.linuxcontainers.org:8443", 
      #     alias: "ubuntu/xenial/amd64",
      #     auto_update: true)
      #
      # @example Store properties with the imported image (will be applied on top of any source properties)
      #   Hyperkit.client.create_image_from_remote("https://images.linuxcontainers.org:8443",
      #     alias: "ubuntu/xenial/amd64",
      #     properties: {
      #       hello: "world"
      #     }
      #   )
      def create_image_from_remote(server, options={})

        opts = options.slice(:filename, :public, :auto_update)

        if options[:protocol] && ! %w[lxd simplestreams].include?(options[:protocol])
          raise Hyperkit::InvalidProtocol.new("Invalid protocol.  Valid choices: lxd, simplestreams")
        end

        opts[:source] = options.slice(:secret, :protocol, :certificate)
        opts[:source].merge!({
          type: "image", 
          mode: "pull",
          server: server
        })

        if options[:alias].nil? && options[:fingerprint].nil?
          raise Hyperkit::ImageIdentifierRequired.new("Please specify either :alias or :fingerprint")
        end

        opts[:properties] = stringify_properties(options[:properties]) if options[:properties]

        if options[:alias]
          opts[:source][:alias] = options[:alias]
        else
          opts[:source][:fingerprint] = options[:fingerprint]
        end

        response = post images_path, opts
        response[:metadata]

      end

      # Import an image from a remote URL.
      #
      # Note: the URL passed to this method is <b>not</b> the URL of a tarball.  
      # Instead, the URL must return the following headers:
      #
      # * <code>LXD-Image-URL</code> - URL of the image tarball
      # * <code>LXD-Image-Hash</code> - SHA-256 fingerprint of the image tarball
      #
      # The LXD server will first access the URL to obtain the values of these headers.
      # It will then download the tarball specified in the <code>LXD-Image-URL</code> header
      # and verify that its fingerprint matches the value in the <code>LXD-Image-Hash</code> header.
      # If they match, the image will be imported.
      #
      # In Apache, you can set this up using a <code>.htaccess</code> file.  See the <b>Examples</b> section
      # for a sample.
      #
      # @param url [String] URL containing image headers (see above)
      # @param options [Hash] Additional data to be passed
      # @option options [String] :filename Tarball filename to store with the image on the server and used when exporting the image (default: name of file being uploaded).
      # @option options [Boolean] :public Whether or not the image should be publicly-accessible by unauthenticated users (default: false).
      # @option options [Hash] :properties Hash of additional properties to store with the image
      #
      # @example Import a private image
      #   Hyperkit.client.create_image_from_url("http://example.com/ubuntu-14.04")
      #
      # @example Import a public image
      #   Hyperkit.client.create_image_from_url("http://example.com/ubuntu-14.04", public: true)
      #
      # @example Store properties with the uploaded image, and override its filename
      #   Hyperkit.client.create_image_from_url("http://example.com/ubuntu-14.04",
      #     filename: "ubuntu-trusty.tar.gz",
      #     properties: {
      #       os: "ubuntu"
      #       codename: "trusty"
      #       version: "14.04"
      #     }
      #   )
      #
      # @example Example .htaccess file on the source server, located in the /ubuntu-14.04 directory:
      #   # Put an empty index.html in the ubuntu-14.04 directory.
      #   # Note that the 'headers' Apache module must be enabled (a2enmod headers).
      #   <Files index.html>
      #
      #   # Image of the file to download
      #   Header set LXD-Image-URL http://example.com/ubuntu-14.04/ubuntu-14.04-amd64-lxc.tar.xz
      #
      #   # SHA-256 of the file to download
      #   Header set LXD-Image-Hash 097e75d6f7419d3a5e204d8125582f2d7bdd4ee4c35bd324513321c645f0c415
      #   </Files>
      def create_image_from_url(url, options={})

        opts = options.slice(:filename, :public)
        opts[:properties] = stringify_properties(options[:properties]) if options[:properties]
				opts[:source] = {
					type: "url",
					url: url
				}

        response = post images_path, opts
        response[:metadata]
      end

      # Create an image from an existing container.
      #
      # @param name [String] Source container name
      # @param options [Hash] Additional data to be passed
      # @option options [String] :filename Tarball filename to store with the image on the server and used when exporting the image (default: name of file being uploaded).
      # @option options [Boolean] :public Whether or not the image should be publicly-accessible by unauthenticated users (default: false).
      # @option options [Hash] :properties Hash of additional properties to store with the image
      #
      # @example Create a private image from container 'test-container'
      #   Hyperkit.client.create_image_from_container("test-container")
      #
      # @example Create a public image from container 'test-container'
      #   Hyperkit.client.create_image_from_container("test-container", public: true)
      #
      # @example Store properties with the new image, and override its filename
      #   Hyperkit.client.create_image_from_container("test-container",
      #     filename: "ubuntu-trusty.tar.gz",
      #     properties: {
      #       os: "ubuntu"
      #       codename: "trusty"
      #       version: "14.04"
      #     }
      #   )
      def create_image_from_container(name, options={})

        opts = options.slice(:filename, :public, :description)
        opts[:properties] = stringify_properties(options[:properties]) if options[:properties]
				opts[:source] = {
					type: "container",
					name: name
				}

        response = post images_path, opts
        response[:metadata]
      end

      # Create an image from an existing snapshot.
      #
      # @param container [String] Source container name
      # @param snapshot [String] Source snapshot name
      # @param options [Hash] Additional data to be passed
      # @option options [String] :filename Tarball filename to store with the image on the server and used when exporting the image (default: name of file being uploaded).
      # @option options [Boolean] :public Whether or not the image should be publicly-accessible by unauthenticated users (default: false).
      # @option options [Hash] :properties Hash of additional properties to store with the image
      #
      # @example Create a private image from snapshot 'test-container/snapshot1'
      #   Hyperkit.client.create_image_from_snapshot("test-container", "snapshot1")
      #
      # @example Create a public image from snapshot 'test-container/snapshot1'
      #   Hyperkit.client.create_image_from_snapshot("test-container", "snapshot1", public: true)
      #
      # @example Store properties with the new image, and override its filename
      #   Hyperkit.client.create_image_from_snapshot("test-container", "snapshot1",
      #     filename: "ubuntu-trusty.tar.gz",
      #     properties: {
      #       os: "ubuntu"
      #       codename: "trusty"
      #       version: "14.04"
      #     }
      #   )
      def create_image_from_snapshot(container, snapshot, options={})

        opts = options.slice(:filename, :public, :description)
        opts[:properties] = stringify_properties(options[:properties]) if options[:properties]
				opts[:source] = {
					type: "snapshot",
					name: "#{container}/#{snapshot}"
				}

        response = post images_path, opts
        response[:metadata]
      end
 
      # Delete an image
      #
      # @param fingerprint [String] Fingerprint of image to delete
      #
      # @example Delete an image using its fingerprint
      #   image = Hyperkit.client.image_by_alias("ubuntu/xenial/amd64")
      #   Hyperkit.client.delete_image(image[:fingerprint])
      def delete_image(fingerprint)
        response = delete image_path(fingerprint)
        response[:metadata]
      end

      private

      def image_path(fingerprint)
        File.join(images_path, fingerprint)
      end

      def image_alias_path(alias_name)
        File.join(image_aliases_path, alias_name)
      end

      def image_aliases_path
        File.join(images_path, "aliases")
      end

      def images_path
        "/1.0/images"
      end

      # Stringify any property values.  LXD returns an error if 
      # integers are passed, for example
			def stringify_properties(properties)
          properties.inject({}){|h,(k,v)| h[k.to_s] = v.to_s; h}
			end
 
    end

  end

end
