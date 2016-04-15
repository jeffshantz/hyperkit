################################################################################
#                                                                              #
# Modeled on Octokit::Default                                                  #
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

require 'openssl'
require 'hyperkit/middleware/follow_redirects'
require 'hyperkit/response/raise_error'

module Hyperkit

  # Default configuration options for {Client}
  module Default

    # Default API endpoint
    API_ENDPOINT = "https://localhost:8443".freeze

    # Default auto-sync value
    AUTO_SYNC = true

    # Default client certificate file for authentication
    CLIENT_CERT = File.join(ENV['HOME'], '.config', 'lxc', 'client.crt').freeze

    # Default client key file for authentication
    CLIENT_KEY = File.join(ENV['HOME'], '.config', 'lxc', 'client.key').freeze

    # Default media type
    MEDIA_TYPE = 'application/json'

    # In Faraday 0.9, Faraday::Builder was renamed to Faraday::RackBuilder
    RACK_BUILDER_CLASS = defined?(Faraday::RackBuilder) ? Faraday::RackBuilder : Faraday::Builder

		# Default Faraday middleware stack
    MIDDLEWARE = RACK_BUILDER_CLASS.new do |builder|
      builder.use Hyperkit::Middleware::FollowRedirects
      builder.use Hyperkit::Response::RaiseError
      builder.adapter Faraday.default_adapter
    end

    # Default User Agent header string
    USER_AGENT   = "Hyperkit Ruby Gem #{Hyperkit::VERSION}".freeze

    # Default to verifying SSL certificates
    VERIFY_SSL = true

    class << self

      # Default options for Faraday::Connection
      # @return [Hash]
      def connection_options
        {
          :headers => {
            :accept => default_media_type,
            :user_agent => user_agent,
          },
          :ssl => {}
        }
      end

      # Default media type from ENV or {MEDIA_TYPE}
      # @return [String]
      def default_media_type
        ENV['HYPERKIT_DEFAULT_MEDIA_TYPE'] || MEDIA_TYPE
      end

      # Configuration options
      # @return [Hash]
      def options
        Hash[Hyperkit::Configurable.keys.map{|key| [key, send(key)]}]
      end

      # Default API endpoint from ENV or {API_ENDPOINT}
      # @return [String]
      def api_endpoint
        ENV['HYPERKIT_API_ENDPOINT'] || API_ENDPOINT
      end

      # Default auto-sync value from ENV or {AUTO_SYNC}
      def auto_sync
        ENV['HYPERKIT_AUTO_SYNC'] || AUTO_SYNC
      end

      # Default client certificate file from ENV or {CLIENT_CERT}
      # @return [String]
      def client_cert
        ENV['HYPERKIT_CLIENT_CERT'] || CLIENT_CERT
      end

      # Default client key file from ENV or {CLIENT_KEY}
      # @return [String]
      def client_key
        ENV['HYPERKIT_KEY'] || CLIENT_KEY
      end

      # Default middleware stack for Faraday::Connection
      # from {MIDDLEWARE}
      # @return [String]
      def middleware
        MIDDLEWARE
      end

      # Default proxy server URI for Faraday connection from ENV
      # @return [String]
      def proxy
        ENV['HYPERKIT_PROXY']
      end

      # Default User-Agent header string from ENV or {USER_AGENT}
      # @return [String]
      def user_agent
        ENV['HYPERKIT_USER_AGENT'] || USER_AGENT
      end

      # Default to verifying peer SSL certificate
      # @return [Boolean]
      def verify_ssl
        true
      end

    end

  end

end
