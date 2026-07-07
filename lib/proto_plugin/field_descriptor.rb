# frozen_string_literal: true

require "delegate"

module ProtoPlugin
  # A wrapper class around `Google::Protobuf::FieldDescriptorProto`
  # which provides helpers and more idiomatic Ruby access patterns.
  #
  # Any method not defined directly is delegated to the descriptor the wrapper was initialized with.
  #
  # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L242
  #   Google::Protobuf::FieldDescriptorProto
  class FieldDescriptor < SimpleDelegator
    # @return [Google::Protobuf::FieldDescriptorProto]
    attr_reader :descriptor

    # The message descriptor this field was defined within.
    #
    # @return [MessageDescriptor]
    attr_reader :message

    # @param descriptor [Google::Protobuf::FieldDescriptorProto]
    # @param message [MessageDescriptor] The message this field was defined within.
    # @param context [Context]
    def initialize(descriptor, message, context)
      super(descriptor)
      @descriptor = descriptor
      @message = message
      @context = context
    end

    # Resolves the message or enum descriptor referenced by this field.
    #
    # Only message, enum, and group fields reference another type. For scalar
    # fields (or when the referenced type was not included in the request),
    # `nil` is returned.
    #
    # @return [MessageDescriptor] if the field is a message or group type
    # @return [EnumDescriptor] if the field is an enum type
    # @return [nil] if the field is a scalar type or the type was not found
    def type_descriptor
      return if scalar?

      @context.type_by_proto_name(type_name)
    end

    # Returns true if the field is a message type.
    #
    # @return [Boolean]
    def message?
      type == :TYPE_MESSAGE
    end

    # Returns true if the field is an enum type.
    #
    # @return [Boolean]
    def enum?
      type == :TYPE_ENUM
    end

    # Returns true if the field is a group type.
    #
    # @return [Boolean]
    def group?
      type == :TYPE_GROUP
    end

    # Returns true if the field is a scalar type (i.e. not a message, enum, or group).
    #
    # @return [Boolean]
    def scalar?
      !message? && !enum? && !group?
    end

    # Returns true if the field has the `repeated` label.
    #
    # @return [Boolean]
    def repeated?
      label == :LABEL_REPEATED
    end

    # Returns true if the field has the `required` label (proto2 only).
    #
    # @return [Boolean]
    def required?
      label == :LABEL_REQUIRED
    end

    # Returns true if the field has the `optional` label.
    #
    # @note In proto3 all singular fields carry the `optional` label internally.
    #   Use {#proto3_optional?} to detect fields with explicit presence tracking.
    #
    # @return [Boolean]
    def optional?
      label == :LABEL_OPTIONAL
    end

    # Returns true if the field was declared with proto3 explicit presence,
    # i.e. an `optional` keyword in a proto3 file.
    #
    # @return [Boolean]
    def proto3_optional?
      descriptor.proto3_optional
    end
  end
end
