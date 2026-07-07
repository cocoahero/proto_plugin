# frozen_string_literal: true

module ProtoPlugin
  # An object that is responsible for organizing the graph of imported descriptors for
  # a given invocation of a plugin.
  #
  # It provides many helpers for looking up a file, message, or other descriptor.
  class Context
    # Initializes a context from a given `Google::Protobuf::Compiler::CodeGeneratorRequest`.
    def initialize(request:)
      @proto_files = request.proto_file
      index_files_by_filename(request.proto_file)
      index_types_by_proto_name
    end

    # Finds an imported file descriptor with the given `name` attribute.
    #
    # @return [ProtoPlugin::FileDescriptor]
    # @return [nil] if the file was not found
    def file_by_filename(name)
      @files_by_filename[name]
    end

    def type_by_proto_name(name)
      @types_by_proto_name[name]
    end

    # Reads the value of a custom option (an extension of one of the
    # `google.protobuf.*Options` messages) from an options message.
    #
    # The Ruby runtime cannot read extensions from the code-generated option
    # types carried in a `CodeGeneratorRequest`, so this rebuilds a descriptor
    # pool from the request's files and re-decodes the options through it,
    # where the extension is resolvable. The rebuilt pool is memoized.
    #
    # @param options [Google::Protobuf::MessageOptions, Google::Protobuf::FieldOptions, ...]
    #   the raw options message from a descriptor (`descriptor.options`)
    # @param name [String] the fully-qualified extension name, e.g. `"my.pkg.table"`
    # @return the option's value, or `nil` if unset or unknown
    def option(options, name)
      return if options.nil?

      extension = extension_pool.lookup(name)
      return if extension.nil?

      if extension.type == :message
        # google-protobuf's FieldDescriptor#get raises for message-typed
        # extensions (as of 4.35.1), so fail with an explanation rather than
        # a cryptic TypeError or a misleading nil for an option that is set.
        raise NotImplementedError,
          "reading message-typed custom options (#{name}) is not supported by " \
            "the google-protobuf runtime; only scalar and repeated-scalar options can be read"
      end

      options_class = extension_pool.lookup(options.class.descriptor.name)&.msgclass
      return if options_class.nil?

      extension.get(options_class.decode(options.to_proto))
    end

    private

    # A descriptor pool rebuilt from every file in the request. Unlike the
    # generated pool, this one knows about the request's custom-option
    # extensions, so they can be resolved and read.
    #
    # @return [Google::Protobuf::DescriptorPool]
    def extension_pool
      @extension_pool ||= Google::Protobuf::DescriptorPool.new.tap do |pool|
        @proto_files.each { |file| pool.add_serialized_file(file.to_proto) }
      end
    end

    def index_files_by_filename(files)
      @files_by_filename = files.each_with_object({}) do |fd, hash|
        hash[fd.name] = FileDescriptor.new(self, fd)
      end
    end

    def index_types_by_proto_name
      @types_by_proto_name = @files_by_filename.values.each_with_object({}) do |fd, hash|
        package = fd.package || ""
        package = ".#{package}" unless package.empty?
        index_enums_by_name(fd.enums, hash, prefix: package)
        index_messages_by_name(fd.messages, hash, prefix: package)
      end
    end

    def index_enums_by_name(enums, hash, prefix:)
      enums.each do |e|
        hash["#{prefix}.#{e.name}"] = e
      end
    end

    def index_messages_by_name(msgs, hash, prefix:)
      msgs.each do |m|
        path = "#{prefix}.#{m.name}"
        index_enums_by_name(m.enums, hash, prefix: path)
        index_messages_by_name(m.messages, hash, prefix: path)
        hash[path] = m
      end
    end
  end
end
