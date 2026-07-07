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
    include Commentable

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

    # The file descriptor this field belongs to.
    #
    # @return [FileDescriptor]
    def file
      message.file
    end

    # Resolves the message or enum descriptor referenced by this field.
    #
    # Only message, enum, and group fields reference another type. For scalar
    # and map fields (or when the referenced type was not included in the
    # request), `nil` is returned. For a map field, inspect {#key} and {#value}
    # instead.
    #
    # @return [MessageDescriptor] if the field is a message or group type
    # @return [EnumDescriptor] if the field is an enum type
    # @return [nil] if the field is a scalar or map type, or the type was not found
    def type_descriptor
      return unless message? || enum? || group?

      @context.type_by_proto_name(type_name)
    end

    # Returns true if the field is a `map<K, V>` field.
    #
    # A map is represented on the wire as a repeated message of synthetic
    # entries. This detects that representation so callers can treat maps
    # distinctly from repeated message fields.
    #
    # @return [Boolean]
    def map?
      !map_entry.nil?
    end

    # The map key field, for a map field.
    #
    # @return [FieldDescriptor] the synthetic entry's key field (number 1)
    # @return [nil] if the field is not a map
    def key
      map_entry&.fields&.find { |f| f.number == 1 }
    end

    # The map value field, for a map field.
    #
    # @return [FieldDescriptor] the synthetic entry's value field (number 2)
    # @return [nil] if the field is not a map
    def value
      map_entry&.fields&.find { |f| f.number == 2 }
    end

    # Returns true if the field is a message type. Map fields are excluded; use
    # {#map?} to detect those.
    #
    # @return [Boolean]
    def message?
      type == :TYPE_MESSAGE && !map?
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

    # Returns true if the field is a scalar type (i.e. not a message, enum,
    # group, or map).
    #
    # @return [Boolean]
    def scalar?
      !map? && !message? && !enum? && !group?
    end

    # Returns true if the field has the `repeated` label. Map fields are
    # excluded; use {#map?} to detect those.
    #
    # @return [Boolean]
    def repeated?
      repeated_label? && !map?
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

    # Returns true if the field is a member of a oneof.
    #
    # @note Fields declared with the proto3 `optional` keyword are backed by a
    #   synthetic oneof. Those are not considered oneof members here.
    #
    # @return [Boolean]
    def oneof?
      descriptor.has_oneof_index? && !proto3_optional?
    end

    # The oneof this field is a member of, if any.
    #
    # @return [OneofDescriptor] if the field is a member of a oneof
    # @return [nil] otherwise
    def oneof
      return unless oneof?

      message.oneofs[descriptor.oneof_index]
    end

    private

    def repeated_label?
      label == :LABEL_REPEATED
    end

    # The synthetic map-entry message backing a map field, if this is one.
    #
    # A map field is a repeated message whose type is a nested message flagged
    # with the `map_entry` option. The entry is resolved directly from the
    # containing message's raw `nested_type` (rather than the context) because
    # synthetic entries are intentionally excluded from {MessageDescriptor#messages}
    # and therefore from the context's type index.
    #
    # @return [MessageDescriptor]
    # @return [nil] if the field is not a map
    def map_entry
      return @map_entry if defined?(@map_entry)

      @map_entry = if repeated_label? && type == :TYPE_MESSAGE
        name = type_name.split(".").last
        proto = message.descriptor.nested_type.find do |n|
          n.name == name && n.options&.map_entry
        end
        MessageDescriptor.new(proto, message, @context) if proto
      end
    end
  end
end
