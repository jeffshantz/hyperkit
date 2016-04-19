################################################################################
#                                                                              #
# Modeled on Octokit::Client                                                   #
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


require 'hyperkit/configurable'
require 'hyperkit/connection'
require 'hyperkit/utility'
require 'hyperkit/client/certificates'
require 'hyperkit/client/containers'
require 'hyperkit/client/images'
require 'hyperkit/client/networks'
require 'hyperkit/client/operations'
require 'hyperkit/client/profiles'

module Hyperkit

  # LXD client
  # @see Hyperkit::Client::Certificates
  # @see Hyperkit::Client::Containers
  # @see Hyperkit::Client::Images
  # @see Hyperkit::Client::Networks
  # @see Hyperkit::Client::Operations
  # @see Hyperkit::Client::Profiles
  class Client

    include Hyperkit::Configurable
    include Hyperkit::Connection
    include Hyperkit::Utility
    include Hyperkit::Client::Certificates
    include Hyperkit::Client::Containers
    include Hyperkit::Client::Images
    include Hyperkit::Client::Networks
    include Hyperkit::Client::Operations
    include Hyperkit::Client::Profiles

    # Initialize a new Hyperkit client
    #
    # @param options [Hash] Any of the attributes listed in {Hyperkit::Configurable}
    #
    # @example Use a client with default options
    #   client = Hyperkit.client
    #
    # @example Create a new client and override the <code>api_endpoint</code>
    #   client = Hyperkit::Client.new(api_endpoint: "https://images.linuxcontainers.org:8443")
    def initialize(options = {})

      # Use options passed in, but fall back to module defaults
      Hyperkit::Configurable.keys.each do |key|

        # Allow user to explicitly override default values by passing 'key: nil'
        next if options.has_key?(key) && options[key].nil?

        if options.has_key?(key)
          value = options[key]
        else
          value = Hyperkit.instance_variable_get(:"@#{key}")
        end

        instance_variable_set(:"@#{key}", value)
      end

    end

  end

end
