require 'hyperkit/configurable'
require 'hyperkit/connection'
require 'hyperkit/client/certificates'
require 'hyperkit/client/images'
require 'hyperkit/client/networks'
require 'hyperkit/client/operations'
require 'hyperkit/client/profiles'

module Hyperkit

  class Client

    include Hyperkit::Configurable
    include Hyperkit::Connection
    include Hyperkit::Client::Certificates
    include Hyperkit::Client::Images
    include Hyperkit::Client::Networks
    include Hyperkit::Client::Operations
    include Hyperkit::Client::Profiles

    def initialize(options = {})
      # Use options passed in, but fall back to module defaults
      Hyperkit::Configurable.keys.each do |key|
        # Allow user to explicitly override default values by passing 'key: nil'
        next if options.has_key?(key) && options[key].nil?

        instance_variable_set(:"@#{key}", options[key] || Hyperkit.instance_variable_get(:"@#{key}"))
      end
    end

  end

end
