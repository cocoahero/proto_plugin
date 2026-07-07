# frozen_string_literal: true

require "test_helper"

module ProtoPlugin
  class FieldDescriptorTest < Minitest::Test
    def setup
      @context = Context.new(request: load_request_fixture)
      @article = @context.type_by_proto_name(".proto_plugin.fixtures.Article")
      @fields = @article.fields.each_with_object({}) do |field, hash|
        hash[field.name] = field
      end
    end

    def test_message
      assert_equal(@article, @fields["title"].message)
    end

    def test_scalar_type_predicates
      title = @fields["title"]

      assert(title.scalar?)
      refute(title.message?)
      refute(title.enum?)
      refute(title.group?)
    end

    def test_message_type_predicates
      author = @fields["author"]

      assert(author.message?)
      refute(author.scalar?)
      refute(author.enum?)
    end

    def test_type_descriptor_for_scalar
      assert_nil(@fields["title"].type_descriptor)
    end

    def test_type_descriptor_for_message
      author = @fields["author"].type_descriptor

      assert_instance_of(MessageDescriptor, author)
      assert_equal("ProtoPlugin::Fixtures::Article::Author", author.full_name)
    end

    def test_type_descriptor_for_repeated_message
      comment = @fields["comments"].type_descriptor

      assert_instance_of(MessageDescriptor, comment)
      assert_equal("ProtoPlugin::Fixtures::Comment", comment.full_name)
    end

    def test_type_descriptor_for_imported_message
      timestamp = @fields["published_at"].type_descriptor

      assert_instance_of(MessageDescriptor, timestamp)
      assert_equal("Timestamp", timestamp.name)
    end

    def test_type_descriptor_returns_nil_for_unindexed_type
      field = FieldDescriptor.new(
        Google::Protobuf::FieldDescriptorProto.new(
          name: "mystery",
          type: :TYPE_MESSAGE,
          type_name: ".does.not.Exist",
        ),
        @article,
        @context,
      )

      assert(field.message?)
      assert_nil(field.type_descriptor)
    end

    def test_cardinality
      assert(@fields["comments"].repeated?)
      refute(@fields["comments"].optional?)

      assert(@fields["title"].optional?)
      refute(@fields["title"].repeated?)
      refute(@fields["title"].required?)
    end

    def test_proto3_optional
      refute(@fields["title"].proto3_optional?)
    end

    def test_delegates_to_descriptor
      title = @fields["title"]

      assert_equal("title", title.name)
      assert_equal(2, title.number)
    end
  end
end
