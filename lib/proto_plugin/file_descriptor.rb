# frozen_string_literal: true

require "delegate"

module ProtoPlugin
  # A wrapper class around `Google::Protobuf::FileDescriptorProto`
  # which provides helpers and more idiomatic Ruby access patterns.
  #
  # Any method not defined directly is delegated to the descriptor the wrapper was initialized with.
  #
  # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L97
  #   Google::Protobuf::FileDescriptorProto
  class FileDescriptor < SimpleDelegator
    include Commentable

    # @return [Google::Protobuf::FileDescriptorProto]
    attr_reader :descriptor

    # @param context [Context]
    # @param descriptor [Google::Protobuf::FileDescriptorProto]
    def initialize(context, descriptor)
      super(descriptor)
      @context = context
      @descriptor = descriptor
    end

    # The file descriptor this element belongs to.
    #
    # For a `FileDescriptor` this is the descriptor itself. Defined so that
    # {Commentable} can resolve comments uniformly across all descriptor types.
    #
    # @return [FileDescriptor]
    def file
      self
    end

    # Returns the `SourceCodeInfo::Location` for a given raw descriptor proto
    # defined within this file, if source info was included in the request.
    #
    # @param proto [Object] a raw descriptor proto contained in this file
    # @return [Google::Protobuf::SourceCodeInfo::Location]
    # @return [nil] if no matching location is available
    def location_for(proto)
      source_locations[proto]
    end

    # The enums defined as children of this file.
    #
    # @return [Array<EnumDescriptor>]
    #
    # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L111
    #   Google::Protobuf::DescriptorProto#enum_type
    def enums
      @enums ||= @descriptor.enum_type.map do |e|
        EnumDescriptor.new(e, self)
      end
    end

    # The messages defined as children of this file.
    #
    # @return [Array<MessageDescriptor>]
    #
    # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L110
    #   Google::Protobuf::DescriptorProto#message_type
    def messages
      @messages ||= @descriptor.message_type.map do |m|
        MessageDescriptor.new(m, self, @context)
      end
    end

    # Returns the Ruby namespace (module) for the file.
    #
    # If the `ruby_package` option was specified, then that value
    # is returned directly. Otherwise, the `package` value is
    # transformed to Ruby module notation.
    #
    # @example Using `package my.protobuf.package;`
    #   file.namespace #=> "My::Protobuf::Package"
    # @example Using `option ruby_package = "My::Ruby::Package";`
    #   file.namespace #=> "My::Ruby::Package"
    #
    # @param split [Boolean] Returns the namespace as an array of module names.
    #
    # @return [String] The namespace for the file.
    # @return [Array<String>] If `split: true`, the namespace as an array of module names.
    def namespace(split: false)
      @namespace ||= begin
        namespace = @descriptor.options&.ruby_package
        if !namespace || namespace.empty?
          namespace = @descriptor.package.split(".")
            .map { |token| Utils.camelize(token) }
            .join("::")
        end
        namespace
      end
      split ? @namespace.split("::") : @namespace
    end

    # The services defined in this file.
    #
    # @return [Array<ServiceDescriptor>]
    #
    # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L112
    #   Google::Protobuf::DescriptorProto#service
    def services
      @services ||= @descriptor.service.map do |s|
        ServiceDescriptor.new(s, self, @context)
      end
    end

    private

    # Field numbers of the relevant repeated fields within their parent
    # descriptor proto, used to construct `SourceCodeInfo` paths.
    #
    # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto
    FILE_MESSAGE = 4
    FILE_ENUM = 5
    FILE_SERVICE = 6
    MESSAGE_FIELD = 2
    MESSAGE_NESTED = 3
    MESSAGE_ENUM = 4
    MESSAGE_ONEOF = 8
    ENUM_VALUE = 2
    SERVICE_METHOD = 2
    private_constant :FILE_MESSAGE,
      :FILE_ENUM,
      :FILE_SERVICE,
      :MESSAGE_FIELD,
      :MESSAGE_NESTED,
      :MESSAGE_ENUM,
      :MESSAGE_ONEOF,
      :ENUM_VALUE,
      :SERVICE_METHOD

    # Builds a map from each raw descriptor proto within this file to its
    # `SourceCodeInfo::Location`, keyed by object identity.
    #
    # The `SourceCodeInfo` locations are addressed by a numeric path into the
    # `FileDescriptorProto` tree. This walks that tree in the same order,
    # reconstructing each path and associating it with the descriptor found
    # there.
    #
    # @return [Hash]
    def source_locations
      @source_locations ||= begin
        by_path = (@descriptor.source_code_info&.location || []).each_with_object({}) do |loc, hash|
          hash[loc.path.to_a] = loc
        end

        index = {}.compare_by_identity
        assign = ->(proto, path) { (loc = by_path[path]) && index[proto] = loc }

        assign.call(@descriptor, [])

        visit_enum = ->(enum, path) {
          assign.call(enum, path)
          enum.value.each_with_index { |v, i| assign.call(v, path + [ENUM_VALUE, i]) }
        }

        visit_message = ->(message, path) {
          assign.call(message, path)
          message.field.each_with_index { |f, i| assign.call(f, path + [MESSAGE_FIELD, i]) }
          message.oneof_decl.each_with_index { |o, i| assign.call(o, path + [MESSAGE_ONEOF, i]) }
          message.enum_type.each_with_index { |e, i| visit_enum.call(e, path + [MESSAGE_ENUM, i]) }
          message.nested_type.each_with_index { |n, i| visit_message.call(n, path + [MESSAGE_NESTED, i]) }
        }

        @descriptor.message_type.each_with_index { |m, i| visit_message.call(m, [FILE_MESSAGE, i]) }
        @descriptor.enum_type.each_with_index { |e, i| visit_enum.call(e, [FILE_ENUM, i]) }
        @descriptor.service.each_with_index do |s, i|
          sp = [FILE_SERVICE, i]
          assign.call(s, sp)
          s["method"].each_with_index { |m, j| assign.call(m, sp + [SERVICE_METHOD, j]) }
        end

        index
      end
    end
  end
end
