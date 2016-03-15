require 'hyperkit/configurable'
require 'hyperkit/connection'
require 'hyperkit/client/operations'
require 'hyperkit/client/profiles'

module Hyperkit

  class Client

    include Hyperkit::Configurable
    include Hyperkit::Connection
    include Hyperkit::Client::Operations
    include Hyperkit::Client::Profiles

    def initialize(options = {})
      # Use options passed in, but fall back to module defaults
      Hyperkit::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", options[key] || Hyperkit.instance_variable_get(:"@#{key}"))
      end
    end

  end

end
