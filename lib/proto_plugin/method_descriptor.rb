# frozen_string_literal: true

require "delegate"

module ProtoPlugin
  # A wrapper class around `Google::Protobuf::MethodDescriptorProto`
  # which provides helpers and more idiomatic Ruby access patterns.
  #
  # Any method not defined directly is delegated to the descriptor the wrapper was initialized with.
  #
  # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L381
  class MethodDescriptor < SimpleDelegator
    include Commentable

    # @return [Google::Protobuf::MethodDescriptorProto]
    attr_reader :descriptor

    # The service this method was defined in.
    #
    # @return [ServiceDescriptor]
    attr_reader :service

    # @param descriptor [Google::Protobuf::MethodDescriptorProto]
    # @param service [ServiceDescriptor] The service this method was defined in.
    # @param context [Context]
    def initialize(descriptor, service, context)
      super(descriptor)
      @descriptor = descriptor
      @service = service
      @context = context
    end

    # The file descriptor this method belongs to.
    #
    # @return [FileDescriptor]
    def file
      service.file
    end

    # Returns the `MessageDescriptor` of the method's input type.
    #
    # @return [MessageDescriptor]
    def input
      @context.type_by_proto_name(input_type)
    end

    # Returns the `MessageDescriptor` of the method's output type.
    #
    # @return [MessageDescriptor]
    def output
      @context.type_by_proto_name(output_type)
    end

    # Returns true if the client may stream multiple client messages.
    #
    # @return [Boolean]
    def client_streaming?
      descriptor.client_streaming
    end

    # Returns true if the server may stream multiple server messages.
    #
    # @return [Boolean]
    def server_streaming?
      descriptor.server_streaming
    end

    # Returns true if both the client and server only may send single messages.
    #
    # @return [Boolean]
    def unary?
      !client_streaming? && !server_streaming?
    end

    # Returns true if both the client and server may send multiple streamed messages.
    #
    # @return [Boolean]
    def bidirectional_streaming?
      client_streaming? && server_streaming?
    end
  end
end
