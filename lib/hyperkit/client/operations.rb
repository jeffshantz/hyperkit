require 'active_support/core_ext/hash/except'

module Hyperkit

  class Client

    # Methods for the profiles API
    module Operations

      # GET /operations
      def operations
        response = get(operations_path)
        response.metadata.to_h.values.flatten.map { |path| path.split('/').last }
      end

      # GET /operations/<uuid>
      def operation(uuid)
        get(operation_path(uuid))
      end

      # DELETE /operations/<uuid>
      def cancel_operation(uuid)
        delete(operation_path(uuid))
      end

      # GET /operations/<uuid>/wait
      def wait_for_operation(uuid, timeout=nil)
        url = File.join(operation_path(uuid), "wait")
        url += "?timeout=#{timeout}" if timeout.to_i > 0

        get(url).metadata
      end

      private

      def handle_async(response, sync)

        sync = sync.nil? ? auto_sync : sync

        if sync 
          wait_for_operation(response.id)
        else
          response
        end

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

