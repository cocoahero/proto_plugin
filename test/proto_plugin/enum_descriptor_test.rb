# frozen_string_literal: true

require "test_helper"

module ProtoPlugin
  class EnumDescriptorTest < Minitest::Test
    def setup
      @context = Context.new(request: load_request_fixture)
      @article = @context.type_by_proto_name(".proto_plugin.fixtures.Article")
      @category = @context.type_by_proto_name(".proto_plugin.fixtures.Category")
    end

    def test_full_name_of_file_enum
      assert_equal("ProtoPlugin::Fixtures::Category", @category.full_name)
    end

    def test_full_name_of_message_enum
      enum = @article.enums.first
      assert_equal("ProtoPlugin::Fixtures::Article::Status", enum.full_name)
    end

    def test_values
      assert_equal(
        ["CATEGORY_UNSPECIFIED", "CATEGORY_ANNOUNCEMENT", "CATEGORY_PRODUCT_RELEASE"],
        @category.values.map(&:name),
      )

      @category.values.each do |v|
        assert_instance_of(EnumValueDescriptor, v)
      end
    end
  end
end
