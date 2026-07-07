# frozen_string_literal: true

require "delegate"

module ProtoPlugin
  # A wrapper class around `Google::Protobuf::ServiceDescriptorProto`
  # which provides helpers and more idiomatic Ruby access patterns.
  #
  # Any method not defined directly is delegated to the descriptor the wrapper was initialized with.
  #
  # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L373
  class ServiceDescriptor < SimpleDelegator
    include Commentable

    # @return [Google::Protobuf::ServiceDescriptorProto]
    attr_reader :descriptor

    # The file this service was defined within.
    #
    # @return [FileDescriptor]
    attr_reader :parent

    # @param descriptor [Google::Protobuf::ServiceDescriptorProto]
    # @param parent [FileDescriptor] The file this service was defined within.
    # @param context [Context]
    def initialize(descriptor, parent, context)
      super(descriptor)
      @descriptor = descriptor
      @parent = parent
      @context = context
    end

    # The file descriptor this service belongs to.
    #
    # @return [FileDescriptor]
    def file
      parent.file
    end

    # The full name of the service, including parent namespace.
    #
    # @example
    #   "My::Ruby::Package::ServiceName"
    #
    # @return [String]
    def full_name
      @full_name ||= "#{parent.namespace}::#{name}"
    end

    # The methods defined for the service.
    #
    # @note This method is named `rpc_methods` to avoid conflicting with Object#methods.
    #
    # @return [Array<MethodDescriptor>]
    #
    # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L375
    #   Google::Protobuf::ServiceDescriptorProto#method
    def rpc_methods
      @rpc_methods ||= @descriptor["method"].map do |m|
        MethodDescriptor.new(m, self, @context)
      end
    end
  end
end
