# frozen_string_literal: true

require "delegate"

module ProtoPlugin
  # A wrapper class around `Google::Protobuf::DescriptorProto`
  # which provides helpers and more idiomatic Ruby access patterns.
  #
  # Any method not defined directly is delegated to the descriptor the wrapper was initialized with.
  #
  # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L134
  #   Google::Protobuf::DescriptorProto
  class MessageDescriptor < SimpleDelegator
    include Commentable

    # @return [Google::Protobuf::DescriptorProto]
    attr_reader :descriptor

    # The file or message descriptor this message was defined within.
    #
    # @return [FileDescriptor] if defined as a root message
    # @return [MessageDescriptor] if defined as a nested message (inverse of `nested_type`)
    attr_reader :parent

    # @param descriptor [Google::Protobuf::DescriptorProto]
    # @param parent [FileDescriptorFileDescriptorProto, MessageDescriptor]
    #   The file or message descriptor this message was defined within.
    # @param context [Context]
    def initialize(descriptor, parent, context)
      super(descriptor)
      @descriptor = descriptor
      @parent = parent
      @context = context
    end

    # The file descriptor this message belongs to.
    #
    # @return [FileDescriptor]
    def file
      parent.file
    end

    # The fields defined on this message.
    #
    # @return [Array<FieldDescriptor>]
    #
    # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L138
    #   Google::Protobuf::DescriptorProto#field
    def fields
      @fields ||= @descriptor.field.map do |f|
        FieldDescriptor.new(f, self, @context)
      end
    end

    # The oneofs defined on this message.
    #
    # @return [Array<OneofDescriptor>]
    #
    # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L145
    #   Google::Protobuf::DescriptorProto#oneof_decl
    def oneofs
      @oneofs ||= @descriptor.oneof_decl.each_with_index.map do |o, i|
        OneofDescriptor.new(o, self, i)
      end
    end

    # The enums defined as children of this message.
    #
    # @return [Array<EnumDescriptor>]
    #
    # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L141
    #   Google::Protobuf::DescriptorProto#enum_type
    def enums
      @enums ||= @descriptor.enum_type.map do |e|
        EnumDescriptor.new(e, self)
      end
    end

    # The messages defined as children of this message.
    #
    # @return [Array<MessageDescriptor>]
    #
    # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L140
    #   Google::Protobuf::DescriptorProto#nested_type
    def messages
      @nested_messages ||= @descriptor.nested_type.map do |m|
        MessageDescriptor.new(m, self, @context)
      end
    end

    # The full name of the message, including parent namespace.
    #
    # @example
    #   "My::Ruby::Package::MessageName"
    #
    # @return [String]
    def full_name
      @full_name ||= begin
        prefix = case parent
        when MessageDescriptor
          parent.full_name
        when FileDescriptor
          parent.namespace
        end
        "#{prefix}::#{name}"
      end
    end
  end
end
