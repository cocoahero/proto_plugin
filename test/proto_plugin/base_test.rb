# frozen_string_literal: true

require "test_helper"

module ProtoPlugin
  class BaseTest < Minitest::Test
    class TestPlugin < Base
      def supported_features
        [
          Google::Protobuf::Compiler::CodeGeneratorResponse::Feature::FEATURE_PROTO3_OPTIONAL,
          Google::Protobuf::Compiler::CodeGeneratorResponse::Feature::FEATURE_SUPPORTS_EDITIONS,
        ]
      end

      def run
        add_file(path: "test.rb", content: "TestPlugin#generate")
      end
    end

    def setup
      @request = load_request_fixture
      @plugin = TestPlugin.new(request: @request)
    end

    def test_adding_files
      @plugin.add_file(path: "foo.txt", content: "Hello World!")
      @plugin.add_file(path: "bar.txt", content: "Hello World, Again!")

      assert_equal(2, @plugin.response.file.count)

      assert_equal("foo.txt", @plugin.response.file.first.name)
      assert_equal("Hello World!", @plugin.response.file.first.content)

      assert_equal("bar.txt", @plugin.response.file.last.name)
      assert_equal("Hello World, Again!", @plugin.response.file.last.content)
    end

    def test_files_to_generate
      files = @plugin.files_to_generate

      assert_equal(4, files.count)

      files.each do |f|
        assert_instance_of(FileDescriptor, f)
      end
    end

    def test_lookup_file
      refute_nil(@plugin.lookup_file(name: "article.proto"))
      refute_nil(@plugin.lookup_file(name: "comment.proto"))
      refute_nil(@plugin.lookup_file(name: "service.proto"))
      assert_nil(@plugin.lookup_file(name: "missing.proto"))
    end

    def test_parameters
      plugin = TestPlugin.new(request: Google::Protobuf::Compiler::CodeGeneratorRequest.new(
        parameter: "foo=bar,bare",
      ))

      expected = {
        "foo" => "bar",
        "bare" => nil,
      }

      assert_equal(expected, plugin.parameters)
    end

    def test_parameters_with_empty_request
      plugin = TestPlugin.new(request: Google::Protobuf::Compiler::CodeGeneratorRequest.new)

      assert_equal({}, plugin.parameters)
    end

    def test_supported_features
      # bitwise or of enum values
      # https://github.com/protocolbuffers/protobuf/blob/v28.0/src/google/protobuf/compiler/plugin.proto#L94-L96
      expected = Google::Protobuf::Compiler::CodeGeneratorResponse::Feature::FEATURE_PROTO3_OPTIONAL |
        Google::Protobuf::Compiler::CodeGeneratorResponse::Feature::FEATURE_SUPPORTS_EDITIONS
      assert_equal(expected, @plugin.response.supported_features)
    end

    def test_run_bang_calls_instance_run
      input = StringIO.new
      output = StringIO.new
      response = TestPlugin.run!(input: input, output: output)

      assert_equal(1, response.file.count)
      assert_equal("test.rb", response.file.first.name)
      assert_equal("TestPlugin#generate", response.file.first.content)
    end

    def test_run_bang_writes_to_specified_output_stream
      input = StringIO.new
      output = StringIO.new
      response = TestPlugin.run!(input: input, output: output)
      assert_equal(response.to_proto, output.string)
    end
  end
end
