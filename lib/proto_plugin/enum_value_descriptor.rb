# frozen_string_literal: true

require "delegate"

module ProtoPlugin
  # A wrapper class around `Google::Protobuf::EnumValueDescriptorProto`
  # which provides helpers and more idiomatic Ruby access patterns.
  #
  # Any method not defined directly is delegated to the descriptor the wrapper was initialized with.
  #
  # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L356
  #   Google::Protobuf::EnumValueDescriptorProto
  class EnumValueDescriptor < SimpleDelegator
    # @return [Google::Protobuf::EnumValueDescriptorProto]
    attr_reader :descriptor

    # The enum descriptor this value was defined within.
    #
    # @return [EnumDescriptor]
    attr_reader :enum

    # @param descriptor [Google::Protobuf::EnumValueDescriptorProto]
    # @param enum [EnumDescriptor] The enum this value was defined within.
    def initialize(descriptor, enum)
      super(descriptor)
      @descriptor = descriptor
      @enum = enum
    end

    # The full name of the enum value, including parent namespace.
    #
    # @example
    #   "My::Ruby::Package::EnumName::VALUE_NAME"
    #
    # @return [String]
    def full_name
      @full_name ||= "#{enum.full_name}::#{name}"
    end
  end
end
