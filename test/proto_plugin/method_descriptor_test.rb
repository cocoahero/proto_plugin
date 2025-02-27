# frozen_string_literal: true

require "test_helper"

module ProtoPlugin
  class MethodDescriptorTest < Minitest::Test
    def setup
      @context = Context.new(request: load_request_fixture)

      @file = @context.file_by_filename("service.proto")

      @service = @file.services.first
      @methods = @service.rpc_methods.each_with_object({}) do |rpc, hash|
        hash[rpc.name] = rpc
      end
    end

    def test_input
      get_article = @methods["GetArticle"]

      refute_nil(get_article)

      assert_equal(".proto_plugin.fixtures.GetArticleRequest", get_article.input_type)

      get_article_request = get_article.input
      assert_instance_of(MessageDescriptor, get_article_request)
      assert_equal("ProtoPlugin::Fixtures::GetArticleRequest", get_article_request.full_name)
    end

    def test_output
      get_article = @methods["GetArticle"]

      refute_nil(get_article)

      assert_equal(".proto_plugin.fixtures.GetArticleResponse", get_article.output_type)

      get_article_response = get_article.output
      assert_instance_of(MessageDescriptor, get_article_response)
      assert_equal("ProtoPlugin::Fixtures::GetArticleResponse", get_article_response.full_name)
    end

    def test_streaming
      article_stream = @methods["ArticleStream"]

      refute_nil(article_stream)

      refute(article_stream.unary?)
      refute(article_stream.client_streaming?)
      assert(article_stream.server_streaming?)
      refute(article_stream.bidirectional_streaming?)
    end
  end
end
