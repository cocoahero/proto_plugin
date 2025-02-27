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
    # @return [Google::Protobuf::FileDescriptorProto]
    attr_reader :descriptor

    # @param context [Context]
    # @param descriptor [Google::Protobuf::FileDescriptorProto]
    def initialize(context, descriptor)
      super(descriptor)
      @context = context
      @descriptor = descriptor
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
        MessageDescriptor.new(m, self)
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
  end
end
