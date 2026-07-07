# frozen_string_literal: true

module ProtoPlugin
  # A mixin providing access to the custom options set on a descriptor.
  #
  # Custom options are user-defined extensions of the `google.protobuf.*Options`
  # messages. The heavy lifting (rebuilding a descriptor pool that knows about
  # the request's extensions and re-decoding the options through it) is handled
  # by {Context}; this just exposes a clean accessor.
  #
  # Including classes must respond to `#file` (to reach the {Context}) and
  # `#descriptor` (whose `options` the value is read from).
  #
  # @see https://protobuf.dev/programming-guides/proto3/#customoptions
  module Optionable
    # Reads the value of a custom option set on this element.
    #
    # @example `message User { option (my.pkg.table) = "users"; }`
    #   message.option("my.pkg.table") #=> "users"
    #
    # @param name [String] the fully-qualified extension name of the option
    # @return the option's value, or `nil` if it was not set
    def option(name)
      file.context.option(descriptor.options, name)
    end
  end
end
