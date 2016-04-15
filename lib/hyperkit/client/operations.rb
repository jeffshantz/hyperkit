require 'active_support/core_ext/hash/except'

module Hyperkit

  class Client

    # Methods for the operations API
    # 
    # @see Hyperkit::Client
    # @see https://github.com/lxc/lxd/blob/master/specs/rest-api.md
    module Operations

      # List of operations active on the server
      #
      # This will include operations that are currently executing, as well as
      # operations that are paused until {#wait_for_operation} is called, at
      # which time they will begin executing. 
      #
      # Additionally, since LXD keeps completed operations around for 5 seconds,
      # the list returned may include recently completed operations.
      #
      # @return [Array<String>] An array of UUIDs identifying waiting, active, and recently completed (<5 seconds) operations
      #
      # @example Get list of operations
      #   Hyperkit.operations #=> ["931e27fb-2057-4cbe-a49d-fd114713fa74"]
      def operations
        response = get(operations_path)
        response.metadata.to_h.values.flatten.map { |path| path.split('/').last }
      end

      # Retrieve information about an operation
      #
      # @param [String] uuid UUID of the operation
      # @return [Sawyer::Resource] Operation information
      #
      # @example Retrieve information about an operation
      #   Hyperkit.operation("d5f359ae-ddcb-4f09-a8f8-0cc2f3c8b0df") #=> {
      #     :id => "d5f359ae-ddcb-4f09-a8f8-0cc2f3c8b0df",
      #     :class => "task",
      #     :created_at => 2016-04-14 21:30:59 UTC,
      #     :updated_at => 2016-04-14 21:30:59 UTC,
      #     :status => "Running",
      #     :status_code => 103, 
      #     :resources => {
      #       :containers => ["/1.0/containers/test-container"]
      #     },
      #     :metadata => nil,
      #     :may_cancel => false,
      #     :err => ""
      #   }
      def operation(uuid)
        get(operation_path(uuid)).metadata
      end

      # Cancel a running operation
      #
      # Calling this will change the state of the operation to 
      # <code>cancelling</code>.  Note that the operation must be cancelable,
      # which can be ascertained by calling {#operation} and checking the 
      # <code>may_cancel</code> property.
      #
      # @param [String] uuid UUID of the operation
      # @return [Sawyer::Resource] 
      #
      # @example Cancel an operation
      #   Hyperkit.cancel_operation("8b3dd0c2-9dad-4964-b00d-e21481a47fb8") => {}
      def cancel_operation(uuid)
        delete(operation_path(uuid)).metadata
      end

      # Wait for an asynchronous operation to complete
      #
      # Note that this is only needed if {#Hyperkit::auto_sync} has been
      # set to <code>false</code>, or if the option <code>sync: false</code>
      # has been passed to an asynchronous method.
      #
      # @param [String] uuid UUID of the operation
      # @param [Fixnum] timeout Maximum time to wait (default: indefinite)
      # @return [Sawyer::Resource] Operation result
      #
      # @example Wait for the creation of a container
      #   Hyperkit.auto_sync = false
      #   op = Hyperkit.create_container("test-container", alias: "ubuntu/amd64/default")
      #   Hyperkit.wait_for_operation(op.id)
      #
      # @example Wait, but time out if the operation is not complete after 30 seconds
      #   op = Hyperkit.copy_container("test1", "test2", sync: false)
      #   Hyperkit.wait_for_operation(op.id, timeout: 30)
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

