# frozen_string_literal: true

require "google/protobuf"
require "google/protobuf/plugin_pb"

module ProtoPlugin
  # The primary base class to inherit from when implementing a plugin.
  #
  # ```ruby
  # require 'proto_plugin'
  #
  # class MyCoolPlugin < ProtoPlugin::Base
  #   def run
  #     # override to provide your implementation
  #   end
  # end
  #
  # MyCoolPlugin.run!
  # ````
  # @abstract
  class Base
    class << self
      ##
      # The preferred way of invoking a plugin.
      #
      # Decodes a `Google::Protobuf::Compiler::CodeGeneratorRequest` message
      # from `input:`, invokes the plugin by calling `#run`, and then encodes
      # `response` to the stream specified by `output:`.
      #
      # @param input [IO] The stream that the request is decoded from.
      # @param output [IO] The stream that the response is encoded to.
      def run!(input: $stdin, output: $stdout)
        plugin = new(
          request: Google::Protobuf::Compiler::CodeGeneratorRequest.decode(
            input.read,
          ),
        )

        plugin.run

        result = plugin.response
        output.write(result.to_proto)
        result
      end
    end

    # The request message the plugin was initialized with.
    # @return [Google::Protobuf::Compiler::CodeGeneratorRequest]
    attr_reader :request

    # The context for the current invocation of the plugin.
    # @return [Context]
    attr_reader :context

    # The response message to be sent back to `protoc`.
    # @return [Google::Protobuf::Compiler::CodeGeneratorResponse]
    attr_reader :response

    # Initializes a new instance of the plugin with a given
    # `Google::Protobuf::Compiler::CodeGeneratorRequest`.
    def initialize(request:)
      @request = request
      @context = Context.new(request: request)
      @response = Google::Protobuf::Compiler::CodeGeneratorResponse.new(
        supported_features: supported_features.reduce(&:|),
      )
    end

    # Convenience method for accessing the parameters passed to the plugin.
    #
    # @example `protoc --myplugin_opt=key=value --myplugin_opt=bare`
    #  {"key" => "value", "bare" => nil}
    #
    # @return [Hash]
    def parameters
      @parameters ||= request.parameter&.split(",")&.each_with_object({}) do |param, hash|
        key, value = param.split("=")
        hash[key] = value
      end
    end

    # Returns an array of `ProtoPlugin::FileDescriptor` representing the files that
    # were passed to `protoc` to be generated.
    #
    # @example `protoc --myplugin_out=. input_one.proto input_two.proto`
    #   [
    #     <ProtoPlugin::FileDescriptor: name: "input_one.proto">,
    #     <ProtoPlugin::FileDescriptor: name: "input_two.proto">
    #   ]
    #
    # @return [Array<FileDescriptor>]
    def files_to_generate
      @files_to_generate ||= request.file_to_generate.filter_map do |filename|
        lookup_file(name: filename)
      end
    end

    # Finds an imported file descriptor with the given `name` attribute.
    #
    # @return [ProtoPlugin::FileDescriptor]
    # @return [nil] if the file was not found
    def lookup_file(name:)
      context.file_by_filename(name)
    end

    # Returns the list of supported `CodeGeneratorResponse::Feature` values by the plugin. The returned
    # values are bitwise or-ed together and set on `response`.
    #
    # Defaults to `CodeGeneratorResponse::Feature::FEATURE_NONE`.
    def supported_features
      [Google::Protobuf::Compiler::CodeGeneratorResponse::Feature::FEATURE_NONE]
    end

    # Convenience method for appending a `CodeGeneratorResponse::File` message to `response`.
    #
    # The path is relative to the directory specified when invoking `protoc`. For example,
    # specifiying `--myplugin_out=gen` will result in `gen/:path`.
    #
    # @param path [String] The relative path to write the file's content.
    # @param content [String] The content which will be written to the file.
    def add_file(path:, content:)
      @response.file << Google::Protobuf::Compiler::CodeGeneratorResponse::File.new(
        name: path, content: content,
      )
    end

    # The primary entrypoint. Override to provide your plugin's implementation.
    # @abstract
    def run
    end
  end
end
