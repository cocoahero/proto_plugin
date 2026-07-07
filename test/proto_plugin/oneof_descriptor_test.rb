# frozen_string_literal: true

require "test_helper"

module ProtoPlugin
  class OneofDescriptorTest < Minitest::Test
    def setup
      @context = Context.new(request: load_request_fixture)
      @message = @context.type_by_proto_name(".proto_plugin.fixtures.CommentEvent")
      @oneof = @message.oneofs.first
    end

    def test_name_and_index
      assert_instance_of(OneofDescriptor, @oneof)
      assert_equal("payload", @oneof.name)
      assert_equal(0, @oneof.index)
    end

    def test_message
      assert_equal(@message, @oneof.message)
    end

    def test_fields
      assert_equal(
        ["created", "edited", "deleted"],
        @oneof.fields.map(&:name),
      )

      @oneof.fields.each do |f|
        assert_instance_of(FieldDescriptor, f)
      end
    end

    def test_fields_excludes_non_members
      refute_includes(@oneof.fields.map(&:name), "comment_id")
    end
  end
end
