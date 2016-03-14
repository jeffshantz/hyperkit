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
    #   @return [String] Base URL for API requests. default: https://localhost:8443/
    # @!attribute client_cert
    #   @return [String] Client certificate for authentication
    # @!attribute client_key
    #   @return [String] Client key for authentication
    # @!attribute connection_options
    #   @see https://github.com/lostisland/faraday
    #   @return [Hash] Configure connection options for Faraday
    # @!attribute default_media_type
    #   @return [String] Configure preferred media type (for API versioning, for example)
    # @!attribute middleware
    #   @see https://github.com/lostisland/faraday
    #   @return [Faraday::Builder or Faraday::RackBuilder] Configure middleware for Faraday
    # @!attribute proxy
    #   @see https://github.com/lostisland/faraday
    #   @return [String] URI for proxy server
    # @!attribute user_agent
    #   @return [String] Configure User-Agent header for requests.

    attr_accessor :client_cert, :client_key, :connection_options,
                  :default_media_type, :middleware, :proxy, :user_agent
    attr_writer :api_endpoint

    class << self

      # List of configurable keys for {Hyperkit::Client}
      # @return [Array] of option keys
      def keys
        @keys ||= [
          :api_endpoint,
          :client_cert,
          :client_key,
          :connection_options,
          :default_media_type,
          :middleware,
          :proxy,
          :user_agent,
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
