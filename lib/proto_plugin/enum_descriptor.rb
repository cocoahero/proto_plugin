# frozen_string_literal: true

require "delegate"

module ProtoPlugin
  # A wrapper class around `Google::Protobuf::EnumDescriptorProto`
  # which provides helpers and more idiomatic Ruby access patterns.
  #
  # Any method not defined directly is delegated to the descriptor the wrapper was initialized with.
  #
  # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L336
  class EnumDescriptor < SimpleDelegator
    include Commentable

    # @return [Google::Protobuf::EnumDescriptorProto]
    attr_reader :descriptor

    # The file or message descriptor this enum was defined within.
    #
    # @return [FileDescriptor] if defined as a root enum
    # @return [MessageDescriptor] if defined as a nested enum (inverse of `enum_type`)
    attr_reader :parent

    # @param descriptor [Google::Protobuf::EnumDescriptorProto]
    # @param parent [FileDescriptorFileDescriptorProto, MessageDescriptor]
    #   The file or message descriptor this enum was defined within.
    def initialize(descriptor, parent)
      super(descriptor)
      @descriptor = descriptor
      @parent = parent
    end

    # The file descriptor this enum belongs to.
    #
    # @return [FileDescriptor]
    def file
      parent.file
    end

    # The values defined for this enum.
    #
    # @return [Array<EnumValueDescriptor>]
    #
    # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L343
    #   Google::Protobuf::EnumDescriptorProto#value
    def values
      @values ||= @descriptor.value.map do |v|
        EnumValueDescriptor.new(v, self)
      end
    end

    # The full name of the enum, including parent namespace.
    #
    # @example
    #   "My::Ruby::Package::EnumName"
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
