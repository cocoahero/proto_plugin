# frozen_string_literal: true

# Easily build protobuf compiler plugins in Ruby.
module ProtoPlugin
end

require_relative "proto_plugin/utils"
require_relative "proto_plugin/context"
require_relative "proto_plugin/commentable"
require_relative "proto_plugin/optionable"
require_relative "proto_plugin/file_descriptor"
require_relative "proto_plugin/enum_descriptor"
require_relative "proto_plugin/enum_value_descriptor"
require_relative "proto_plugin/field_descriptor"
require_relative "proto_plugin/oneof_descriptor"
require_relative "proto_plugin/message_descriptor"
require_relative "proto_plugin/service_descriptor"
require_relative "proto_plugin/method_descriptor"
require_relative "proto_plugin/base"
require_relative "proto_plugin/version"
