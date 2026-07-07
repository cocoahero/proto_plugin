# frozen_string_literal: true

require "delegate"

module ProtoPlugin
  # A wrapper class around `Google::Protobuf::OneofDescriptorProto`
  # which provides helpers and more idiomatic Ruby access patterns.
  #
  # Any method not defined directly is delegated to the descriptor the wrapper was initialized with.
  #
  # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L349
  #   Google::Protobuf::OneofDescriptorProto
  class OneofDescriptor < SimpleDelegator
    include Commentable
    include Optionable

    # @return [Google::Protobuf::OneofDescriptorProto]
    attr_reader :descriptor

    # The message descriptor this oneof was defined within.
    #
    # @return [MessageDescriptor]
    attr_reader :message

    # The index of this oneof within its message's `oneof_decl` list.
    #
    # @return [Integer]
    attr_reader :index

    # @param descriptor [Google::Protobuf::OneofDescriptorProto]
    # @param message [MessageDescriptor] The message this oneof was defined within.
    # @param index [Integer] The index of this oneof within the message.
    def initialize(descriptor, message, index)
      super(descriptor)
      @descriptor = descriptor
      @message = message
      @index = index
    end

    # The file descriptor this oneof belongs to.
    #
    # @return [FileDescriptor]
    def file
      message.file
    end

    # The fields that are members of this oneof.
    #
    # @return [Array<FieldDescriptor>]
    def fields
      @fields ||= message.fields.select do |field|
        field.oneof? && field.oneof_index == index
      end
    end
  end
end
