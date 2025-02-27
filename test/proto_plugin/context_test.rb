# frozen_string_literal: true

require "test_helper"

module ProtoPlugin
  class ContextTest < Minitest::Test
    def setup
      @context = Context.new(
        request: load_request_fixture,
      )
    end

    def test_file_by_filename
      refute_nil(@context.file_by_filename("article.proto"))
      refute_nil(@context.file_by_filename("comment.proto"))
      refute_nil(@context.file_by_filename("service.proto"))
      assert_nil(@context.file_by_filename("missing.proto"))
    end

    def test_type_by_proto_name
      assert_nil(@context.type_by_proto_name("foo"))

      article = @context.type_by_proto_name(".proto_plugin.fixtures.Article")
      assert_instance_of(MessageDescriptor, article)

      article_author = @context.type_by_proto_name(".proto_plugin.fixtures.Article.Author")
      assert_instance_of(MessageDescriptor, article_author)

      comment = @context.type_by_proto_name(".proto_plugin.fixtures.Comment")
      assert_instance_of(MessageDescriptor, comment)

      comment_status = @context.type_by_proto_name(".proto_plugin.fixtures.Comment.Status")
      assert_instance_of(EnumDescriptor, comment_status)

      get_article_request = @context.type_by_proto_name(".proto_plugin.fixtures.GetArticleRequest")
      assert_instance_of(MessageDescriptor, get_article_request)
    end
  end
end
