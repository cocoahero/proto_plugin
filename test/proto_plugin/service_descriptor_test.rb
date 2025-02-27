# frozen_string_literal: true

require "test_helper"

module ProtoPlugin
  class ServiceDescriptorTest < Minitest::Test
    def setup
      @context = Context.new(request: load_request_fixture)
      @file = @context.file_by_filename("service.proto")
      @service = @file.services.first
    end

    def test_name
      assert_equal("ArticlesService", @service.name)
    end

    def test_full_name
      assert_equal("ProtoPlugin::Fixtures::ArticlesService", @service.full_name)
    end

    def test_rpc_methods
      assert_equal(3, @service.rpc_methods.count)

      @service.rpc_methods.each do |m|
        assert_instance_of(MethodDescriptor, m)
      end

      assert_equal(
        ["GetArticle", "GetArticles", "ArticleStream"],
        @service.rpc_methods.map(&:name),
      )
    end
  end
end
