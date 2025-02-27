# frozen_string_literal: true

module ProtoPlugin
  # An object that is responsible for organizing the graph of imported descriptors for
  # a given invocation of a plugin.
  #
  # It provides many helpers for looking up a file, message, or other descriptor.
  class Context
    # Initializes a context from a given `Google::Protobuf::Compiler::CodeGeneratorRequest`.
    def initialize(request:)
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

    private

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
