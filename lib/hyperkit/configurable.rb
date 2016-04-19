################################################################################
#                                                                              #
# Modeled on Octokit::Configurable                                             #
#                                                                              #
# Original Octokit license                                                     #
# ---------------------------------------------------------------------------- #
# Copyright (c) 2009-2016 Wynn Netherland, Adam Stacoviak, Erik Michaels-Ober  #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a      #
# copy of this software and associated documentation files (the "Software"),   #
# to deal in the Software without restriction, including without limitation    #
# the rights to use, copy, modify, merge, publish, distribute, sublicense,     #
# and/or sell copies of the Software, and to permit persons to whom the        #
# Software is furnished to do so, subject to the following conditions:         #
#                                                                              #
# The above copyright notice and this permission notice shall be included      #
# in all copies or substantial portions of the Software.                       #
# ---------------------------------------------------------------------------- #
#                                                                              #
################################################################################


module Hyperkit

  # Configuration options for {Client}, defaulting to values
  # in {Default}
  module Configurable

    # @!attribute api_endpoint
    #   @return [String] the base URL for API requests (default: <code>https://localhost:8443/</code>)
    # @!attribute auto_sync
    #   Whether to automatically wait for asynchronous operations to complete
    #
    #   A good deal of the LXD API calls are asynchronous: you issue the call,
    #   and you receive an operation ID.  You must then wait on the operation
    #   to complete.  Each asynchronous method is marked as such in the Hyperkit
    #   documentation.
    #
    #   <b>By default, Hyperkit provides auto-synchronization</b>.  When you
    #   initiate an asynchronous operation, Hyperkit will automatically wait for
    #   the operation to complete before returning.  If you wish to override
    #   this functionality, there are two ways to do this:
    #
    #   * Pass <code>sync: false</code> to any of the asynchronous methods
    #   * Set <code>auto_sync</code> to <code>false</code> at the module or
    #     class level (see examples)
    #
    #   Any asynchronous calls you issue after setting <code>auto_sync</code>
    #   to <code>false</code> will immediately return an operation ID instead of
    #   blocking.  To ensure that an operation is complete, you will need to
    #   call {Hyperkit::Client::Operations#wait_for_operation}.
    #
    #   Most users will likely want to keep <code>auto_sync</code> enabled for
    #   convenience.
    #
    #   @example Create a container and automatically wait for it to complete (auto_sync is <code>true</code> by default)
    #     Hyperkit.create_container("test-container", alias: "ubuntu/trusty/amd64")
    #
    #   @example Disable auto-synchronization at the module level
    #     Hyperkit.auto_sync = false
    #     op = Hyperkit.create_container("test-container", alias: "ubuntu/trusty/amd64")
    #     Hyperkit.wait_for_operation(op.id)
    #
    #   @example Disable auto-synchronization at the class level
    #     client = Hyperkit::Client.new(auto_sync: false)
    #     op = client.create_container("test-container", alias: "ubuntu/trusty/amd64")
    #     client.wait_for_operation(op.id)
    #
    #   @example Disable auto-synchronization, but enable it for one call by passing <code>sync: true</code>
    #     Hyperkit.auto_sync = false
    #     Hyperkit.create_container("test-container", alias: "ubuntu/trusty/amd64", sync: true)
    #   @example Enable auto-synchronization, but disable it for one call by passing <code>sync: false</code>
    #     Hyperkit.auto_sync = true
    #     op = Hyperkit.create_container("test-container", alias: "ubuntu/trusty/amd64", sync: false)
    #     Hyperkit.wait_for_operation(op.id)
    #   @return [String] whether to automatically wait on asynchronous events (default: <code>true</code>)
    # @!attribute client_cert
    #   @return [String] the client certificate used to authenticate to the LXD server
    # @!attribute client_key
    #   @return [String] the client key used to authenticate to the LXD server
    # @!attribute default_media_type
    #   @return [String] the preferred media type (for API versioning, for example)
    # @!attribute middleware
    #   @see https://github.com/lostisland/faraday
    #   @return [Faraday::Builder or Faraday::RackBuilder] middleware for Faraday
    # @!attribute proxy
    #   @see https://github.com/lostisland/faraday
    #   @return [String] the URI of a proxy server used to connect to the LXD server
    # @!attribute user_agent
    #   @return [String] the <code>User-Agent</code> header used for requests made to the LXD server
    # @!attribute verify_ssl
    #   @return [Boolean] whether or not to verify the LXD server's SSL certificate

    attr_accessor :auto_sync, :client_cert, :client_key, :default_media_type,
                  :middleware, :proxy, :user_agent, :verify_ssl

    attr_writer :api_endpoint

    class << self

      # List of configurable keys for {Hyperkit::Client}
      # @return [Array] of option keys
      def keys
        @keys ||= [
          :api_endpoint,
          :auto_sync,
          :client_cert,
          :client_key,
          :default_media_type,
          :middleware,
          :proxy,
          :user_agent,
          :verify_ssl
        ]
      end

    end

    # Set configuration options using a block
    def configure
      yield self
    end

    # Reset configuration options to default values
    def reset!
      Hyperkit::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", Hyperkit::Default.options[key])
      end
      self
    end

    alias setup reset!

    # Compares client options to a Hash of requested options
    #
    # @param opts [Hash] Options to compare with current client options
    # @return [Boolean]
    def same_options?(opts)
      opts.hash == options.hash
    end

    def api_endpoint
      File.join(@api_endpoint, "")
    end

    private

    def options
      Hash[Hyperkit::Configurable.keys.map{|key| [key, instance_variable_get(:"@#{key}")]}]
    end

  end

end
