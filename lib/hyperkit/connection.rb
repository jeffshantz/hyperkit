################################################################################
#                                                                              #
# Based on Octokit::Connection                                                 #
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

require 'sawyer'

module Hyperkit

  # Network layer for API clients.
  module Connection

    # Header keys that can be passed in options hash to {#get},{#head}
    CONVENIENCE_HEADERS = Set.new([:accept, :content_type])

    # Make a HTTP GET request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Query and header params for request
    # @return [Sawyer::Resource]
    def get(url, options = {})
      request :get, url, parse_query_and_convenience_headers(options)
    end

    # Make a HTTP POST request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Body and header params for request
    # @return [Sawyer::Resource]
    def post(url, options = {})
      request :post, url, options
    end

    # Make a HTTP PUT request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Body and header params for request
    # @return [Sawyer::Resource]
    def put(url, options = {})
      request :put, url, options
    end

    # Make a HTTP PATCH request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Body and header params for request
    # @return [Sawyer::Resource]
    def patch(url, options = {})
      request :patch, url, options
    end

    # Make a HTTP DELETE request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Query and header params for request
    # @return [Sawyer::Resource]
    def delete(url, options = {})
      request :delete, url, options
    end

    # Make a HTTP HEAD request
    #
    # @param url [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Query and header params for request
    # @return [Sawyer::Resource]
    def head(url, options = {})
      request :head, url, parse_query_and_convenience_headers(options)
    end

    # Hypermedia agent for the GitHub API
    #
    # @return [Sawyer::Agent]
    def agent
      @agent ||= Sawyer::Agent.new(endpoint, sawyer_options) do |http|
        http.headers[:accept] = default_media_type
        http.headers[:content_type] = "application/json"
        http.headers[:user_agent] = user_agent
      end
    end

    # Fetch the root resource for the API
    #
    # @return [Sawyer::Resource]
    def root
      get "/"
    end

    # Response for last HTTP request
    #
    # @return [Sawyer::Response]
    def last_response
      @last_response if defined? @last_response
    end

    protected

    def endpoint
      api_endpoint
    end

    private

    def reset_agent
      @agent = nil
    end

    def request(method, path, data, options = {})
      if data.is_a?(Hash)
        options[:query]   = data.delete(:query) || {}
        options[:headers] = data.delete(:headers) || {}
        url_encode = data.delete(:url_encode) || true

        if accept = data.delete(:accept)
          options[:headers][:accept] = accept
        end
        if data[:raw_body]
          data = data[:raw_body]
        end
      end

      path = URI::Parser.new.escape(path.to_s) if url_encode

      @last_response = response = agent.call(method, path, data, options)
      response.data
    end

    # Executes the request, checking if it was successful
    #
    # @return [Boolean] True on success, false otherwise
    def boolean_from_response(method, path, options = {})
      request(method, path, options)
      @last_response.status == 204
    rescue Hyperkit::NotFound
      false
    end


    def sawyer_options
      opts = {
        :links_parser => Sawyer::LinkParsers::Simple.new,
      }
      conn_opts = {}
      conn_opts[:builder] = @middleware if @middleware
      conn_opts[:proxy] = @proxy if @proxy

      conn_opts[:ssl] = {
        verify: verify_ssl
      }

      if client_cert && File.exist?(client_cert)
        conn_opts[:ssl][:client_cert] = OpenSSL::X509::Certificate.new(File.read(client_cert))
      end

      if client_key && File.exist?(client_key)
        conn_opts[:ssl][:client_key] = OpenSSL::PKey.read(File.read(client_key))
      end

      opts[:faraday] = Faraday.new(conn_opts)

      opts
    end

    def parse_query_and_convenience_headers(options)
      headers = options.delete(:headers) { Hash.new }
      CONVENIENCE_HEADERS.each do |h|
        if header = options.delete(h)
          headers[h] = header
        end
      end
      query = options.delete(:query)
      opts = {:query => options}
      opts[:query].merge!(query) if query && query.is_a?(Hash)
      opts[:headers] = headers unless headers.empty?

      opts
    end

  end

end
