################################################################################
#                                                                              #
# Based on Octokit                                                             #
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

require 'hyperkit/version'
require 'hyperkit/client'
require 'hyperkit/default'

# Ruby toolkit for the LXD API.
# LXD - The next-generation container hypervisor for Linux
module Hyperkit 

  class << self
    include Hyperkit::Configurable

    # API client based on configured options {Configurable}
    #
    # @return [Hyperkit::Client] API wrapper
    def client
      return @client if defined?(@client) && @client.same_options?(options)
      @client = Hyperkit::Client.new(options)
    end

    private

    def respond_to_missing?(method_name, include_private=false)
      client.respond_to?(method_name, include_private)
    end

    def method_missing(method_name, *args, &block)
      if client.respond_to?(method_name)
        return client.send(method_name, *args, &block)
      end

      super
    end

  end
end

Hyperkit.setup
