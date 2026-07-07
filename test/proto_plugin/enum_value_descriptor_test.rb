# frozen_string_literal: true

require "test_helper"

module ProtoPlugin
  class EnumValueDescriptorTest < Minitest::Test
    def setup
      @context = Context.new(request: load_request_fixture)
      @category = @context.type_by_proto_name(".proto_plugin.fixtures.Category")
      @article = @context.type_by_proto_name(".proto_plugin.fixtures.Article")
    end

    def test_name_and_number
      value = @category.values.first

      assert_instance_of(EnumValueDescriptor, value)
      assert_equal("CATEGORY_UNSPECIFIED", value.name)
      assert_equal(0, value.number)
    end

    def test_enum
      value = @category.values.first
      assert_equal(@category, value.enum)
    end

    def test_full_name_of_file_enum_value
      value = @category.values.last
      assert_equal("ProtoPlugin::Fixtures::Category::CATEGORY_PRODUCT_RELEASE", value.full_name)
    end

    def test_full_name_of_message_enum_value
      status = @article.enums.first
      value = status.values.first
      assert_equal("ProtoPlugin::Fixtures::Article::Status::DRAFT", value.full_name)
    end
  end
end
