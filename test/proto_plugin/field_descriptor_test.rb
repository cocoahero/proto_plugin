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

    def test_scalar_map
      digest = @context.type_by_proto_name(".proto_plugin.fixtures.CommentDigest")
      counts = digest.fields.find { |f| f.name == "counts_by_user" }

      assert(counts.map?)

      # A map is neither a repeated, message, nor scalar field.
      refute(counts.repeated?)
      refute(counts.message?)
      refute(counts.scalar?)
      assert_nil(counts.type_descriptor)

      assert_equal("key", counts.key.name)
      assert(counts.key.scalar?)
      assert_equal("value", counts.value.name)
      assert(counts.value.scalar?)
    end

    def test_message_valued_map
      digest = @context.type_by_proto_name(".proto_plugin.fixtures.CommentDigest")
      comments = digest.fields.find { |f| f.name == "comments_by_id" }

      assert(comments.map?)
      assert(comments.value.message?)
      assert_equal("ProtoPlugin::Fixtures::Comment", comments.value.type_descriptor.full_name)
    end

    def test_repeated_scalar_is_not_a_map
      digest = @context.type_by_proto_name(".proto_plugin.fixtures.CommentDigest")
      labels = digest.fields.find { |f| f.name == "labels" }

      refute(labels.map?)
      assert(labels.repeated?)
      assert(labels.scalar?)
      assert_nil(labels.key)
      assert_nil(labels.value)
    end

    def test_synthetic_map_entries_excluded_from_messages
      digest = @context.type_by_proto_name(".proto_plugin.fixtures.CommentDigest")
      assert_empty(digest.messages)
    end

    def test_type_normalizes_the_enum
      assert_equal(:uint64, @fields["id"].type)
      assert_equal(:string, @fields["title"].type)
      assert_equal(:message, @fields["author"].type)
      assert_equal(:message, @fields["comments"].type) # repeated message
    end

    def test_json_name
      assert_equal("publishedAt", @fields["published_at"].json_name)
      assert_equal("title", @fields["title"].json_name)
    end

    def test_default_value
      field = FieldDescriptor.new(
        Google::Protobuf::FieldDescriptorProto.new(
          name: "count",
          type: :TYPE_INT32,
          default_value: "42",
        ),
        @article,
        @context,
      )

      assert_equal("42", field.default_value)
    end

    def test_default_value_nil_when_absent
      assert_nil(@fields["title"].default_value)
    end

    def test_oneof_membership
      event = @context.type_by_proto_name(".proto_plugin.fixtures.CommentEvent")
      fields = event.fields.each_with_object({}) do |field, hash|
        hash[field.name] = field
      end

      created = fields["created"]
      assert(created.oneof?)
      assert_instance_of(OneofDescriptor, created.oneof)
      assert_equal("payload", created.oneof.name)

      comment_id = fields["comment_id"]
      refute(comment_id.oneof?)
      assert_nil(comment_id.oneof)
    end

    def test_delegates_to_descriptor
      title = @fields["title"]

      assert_equal("title", title.name)
      assert_equal(2, title.number)
    end
  end
end
