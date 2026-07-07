# frozen_string_literal: true

require "test_helper"

module ProtoPlugin
  class OptionableTest < Minitest::Test
    def setup
      @context = Context.new(request: load_request_fixture)
      @comment = @context.type_by_proto_name(".proto_plugin.fixtures.Comment")
    end

    def test_message_option
      assert_equal("comments", @comment.option("proto_plugin.fixtures.table"))
    end

    def test_field_option
      username = @comment.fields.find { |f| f.name == "username" }
      assert_equal(true, username.option("proto_plugin.fixtures.pii"))
    end

    def test_option_nil_when_unset_on_element
      content = @comment.fields.find { |f| f.name == "content" }
      assert_nil(content.option("proto_plugin.fixtures.pii"))
    end

    def test_option_nil_for_unknown_extension
      assert_nil(@comment.option("proto_plugin.fixtures.nonexistent"))
    end

    def test_option_nil_when_element_has_no_options
      article = @context.type_by_proto_name(".proto_plugin.fixtures.Article")
      assert_nil(article.option("proto_plugin.fixtures.table"))
    end
  end
end
