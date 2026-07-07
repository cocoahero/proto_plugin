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
    # A bare option name (no `.`) is resolved relative to this element's file
    # package, matching how the option is declared in the same package. A
    # qualified name (containing a `.`) is used as-is, for options defined in
    # another package.
    #
    # @example An option declared in the element's own package
    #   # message User { option (my.pkg.table) = "users"; }  (package my.pkg)
    #   message.option("table") #=> "users"
    #
    # @example An option from another package
    #   field.option("google.api.field_behavior")
    #
    # Scalar and repeated-scalar options are supported. Message-typed options
    # raise `NotImplementedError`, as the google-protobuf runtime cannot read
    # them.
    #
    # @param name [String] the option's extension name, bare or fully-qualified
    # @return the option's value, or `nil` if it was not set
    # @raise [NotImplementedError] if the option is message-typed
    def option(name)
      file.context.option(descriptor.options, qualified_option_name(name))
    end

    private

    def qualified_option_name(name)
      return name if name.include?(".")

      package = file.package
      package.nil? || package.empty? ? name : "#{package}.#{name}"
    end
  end
end
