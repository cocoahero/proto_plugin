# frozen_string_literal: true

require "test_helper"

module ProtoPlugin
  class MessageDescriptorTest < Minitest::Test
    def setup
      @context = Context.new(request: load_request_fixture)
      @message = @context.type_by_proto_name(".proto_plugin.fixtures.Article")
    end

    def test_name
      assert_equal("Article", @message.name)
    end

    def test_enums
      assert_equal(1, @message.enums.count)
      assert_equal("Status", @message.enums.first.name)
    end

    def test_messages
      assert_equal(2, @message.messages.count)

      child_one = @message.messages[0]
      child_two = @message.messages[1]

      assert_equal("Author", child_one.name)
      assert_equal(@message, child_one.parent)

      assert_equal("Metadata", child_two.name)
      assert_equal(@message, child_two.parent)
    end

    def test_full_name
      child_one = @message.messages[0]
      child_two = @message.messages[1]

      assert_equal("ProtoPlugin::Fixtures::Article", @message.full_name)
      assert_equal("ProtoPlugin::Fixtures::Article::Author", child_one.full_name)
      assert_equal("ProtoPlugin::Fixtures::Article::Metadata", child_two.full_name)
    end
  end
end
