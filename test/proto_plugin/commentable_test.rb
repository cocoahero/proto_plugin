# frozen_string_literal: true

require "test_helper"

module ProtoPlugin
  # Exercises comment resolution (via SourceCodeInfo) across every descriptor type.
  class CommentableTest < Minitest::Test
    def setup
      @context = Context.new(request: load_request_fixture)
      @article = @context.type_by_proto_name(".proto_plugin.fixtures.Article")
    end

    def test_message_comment
      assert_equal(" An article published on the blog.\n", @article.leading_comments)
    end

    def test_field_leading_comment
      id = @article.fields.find { |f| f.name == "id" }
      assert_equal(" The unique identifier for the article.\n", id.leading_comments)
    end

    def test_field_trailing_comment
      title = @article.fields.find { |f| f.name == "title" }
      assert_equal(" The article's headline.\n", title.trailing_comments)
    end

    def test_nested_enum_comment
      status = @article.enums.first
      assert_equal(" The lifecycle status of an article.\n", status.leading_comments)
    end

    def test_enum_value_comment
      draft = @article.enums.first.values.first
      assert_equal(" The article is a work in progress.\n", draft.leading_comments)
    end

    def test_file_level_enum_comment
      category = @context.type_by_proto_name(".proto_plugin.fixtures.Category")
      assert_equal(" A top-level content category.\n", category.leading_comments)
    end

    def test_service_comment
      service = @context.file_by_filename("service.proto").services.first
      assert_equal(" Provides access to articles.\n", service.leading_comments)
    end

    def test_method_comment
      method = @context.file_by_filename("service.proto").services.first.rpc_methods.first
      assert_equal(" Fetches a single article by id.\n", method.leading_comments)
    end

    def test_oneof_comment
      event = @context.type_by_proto_name(".proto_plugin.fixtures.CommentEvent")
      assert_equal(" Describes what happened to the comment.\n", event.oneofs.first.leading_comments)
    end

    def test_comments_aggregates_leading_and_trailing
      title = @article.fields.find { |f| f.name == "title" }
      assert_equal([" The article's headline.\n"], title.comments)

      id = @article.fields.find { |f| f.name == "id" }
      assert_equal([" The unique identifier for the article.\n"], id.comments)
    end

    def test_comments_empty_when_absent
      author = @article.fields.find { |f| f.name == "author" }
      assert_empty(author.comments)
    end

    def test_absent_comments_are_nil
      author = @article.fields.find { |f| f.name == "author" }

      assert_nil(author.leading_comments)
      assert_nil(author.trailing_comments)
      assert_empty(author.leading_detached_comments)
    end

    def test_file_resolves_to_owning_descriptor
      status = @article.enums.first

      assert_instance_of(FileDescriptor, @article.file)
      assert_equal("article.proto", @article.file.name)
      assert_equal(@article.file, status.file)
      assert_equal(@article.file, status.values.first.file)
    end
  end
end
