# frozen_string_literal: true

require "test_helper"

module ProtoPlugin
  class FileDescriptorTest < Minitest::Test
    def setup
      @context = Context.new(request: load_request_fixture)
    end

    def test_name
      file = @context.file_by_filename("article.proto")
      assert_instance_of(FileDescriptor, file)
      assert_equal("article.proto", file.name)
    end

    def test_enums
      file = @context.file_by_filename("category.proto")
      assert_instance_of(FileDescriptor, file)

      assert_equal(2, file.enums.count)

      enum_one = file.enums[0]
      assert_instance_of(EnumDescriptor, enum_one)

      enum_two = file.enums[1]
      assert_instance_of(EnumDescriptor, enum_two)
    end

    def test_messages
      file = @context.file_by_filename("article.proto")
      assert_instance_of(FileDescriptor, file)

      assert_equal(1, file.messages.count)

      message_one = file.messages[0]
      assert_instance_of(MessageDescriptor, message_one)
    end

    def test_services
      file = @context.file_by_filename("service.proto")
      assert_instance_of(FileDescriptor, file)

      assert_equal(1, file.services.count)

      service_one = file.services[0]
      assert_instance_of(ServiceDescriptor, service_one)
    end

    def test_namespace_without_package
      file = FileDescriptor.new(@context, Google::Protobuf::FileDescriptorProto.new(
        name: "sample.proto",
      ))
      assert_equal("", file.namespace)
    end

    def test_namespace_with_package
      file = FileDescriptor.new(@context, Google::Protobuf::FileDescriptorProto.new(
        name: "sample.proto", package: "my.package.name",
      ))
      assert_equal("My::Package::Name", file.namespace)
    end

    def test_namespace_with_ruby_package
      file = FileDescriptor.new(@context, Google::Protobuf::FileDescriptorProto.new(
        name: "sample.proto", options: Google::Protobuf::FileOptions.new(
          ruby_package: "My::Ruby::Namespace",
        )
      ))
      assert_equal("My::Ruby::Namespace", file.namespace)
    end

    def test_namespace_with_package_and_ruby_package
      file = FileDescriptor.new(@context, Google::Protobuf::FileDescriptorProto.new(
        name: "sample.proto", package: "my.package.name", options: Google::Protobuf::FileOptions.new(
          ruby_package: "My::Ruby::Namespace",
        )
      ))
      assert_equal("My::Ruby::Namespace", file.namespace)
    end

    def test_namespace_with_split_option
      file = FileDescriptor.new(@context, Google::Protobuf::FileDescriptorProto.new(
        name: "sample.proto", package: "my.package.name",
      ))
      assert_equal(["My", "Package", "Name"], file.namespace(split: true))
    end
  end
end
