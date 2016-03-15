require 'active_support/core_ext/hash/except'

module Hyperkit

  class Client

    # Methods for the profiles API
    module Operations

      # GET /operations
      def operations
        response = get operations_path
        response[:metadata].to_h.values.flatten.map { |path| path.split('/').last }
      end

      def operations_path 
        "/1.0/operations"
      end
 
    end

  end

end

