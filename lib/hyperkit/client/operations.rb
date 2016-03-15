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

      # GET /operations/<uuid>
      def operation(uuid)
        response = get operation_path(uuid)
        response.to_h
      end

      # GET /operations/<uuid>/wait
      def wait_for_operation(uuid, timeout=nil)
        url = File.join(operation_path(uuid), "wait")
        url += "?timeout=#{timeout}" if timeout.to_i > 0
        response = get url
        response.to_h
      end

      def operation_path(uuid)
        File.join(operations_path, uuid)
      end

      def operations_path 
        "/1.0/operations"
      end
 
    end

  end

end

