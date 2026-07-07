# frozen_string_literal: true

module ProtoPlugin
  # A mixin providing access to the comments associated with a descriptor via
  # its file's `SourceCodeInfo`.
  #
  # Including classes must respond to `#file` (returning the {FileDescriptor}
  # the element belongs to) and `#descriptor` (returning the raw descriptor
  # proto the comments are keyed against).
  #
  # @see https://github.com/protocolbuffers/protobuf/blob/v28.2/src/google/protobuf/descriptor.proto#L1213
  #   Google::Protobuf::SourceCodeInfo::Location
  module Commentable
    # The `SourceCodeInfo::Location` associated with this element, if source
    # info was included in the request.
    #
    # @return [Google::Protobuf::SourceCodeInfo::Location]
    # @return [nil] if no location is available
    def source_location
      file&.location_for(descriptor)
    end

    # The comment block appearing directly above this element.
    #
    # @return [String] the leading comment, as provided by `protoc`
    # @return [nil] if there is no leading comment
    def leading_comments
      presence(source_location&.leading_comments)
    end

    # The comment appearing directly after this element on the same or
    # following line.
    #
    # @return [String] the trailing comment, as provided by `protoc`
    # @return [nil] if there is no trailing comment
    def trailing_comments
      presence(source_location&.trailing_comments)
    end

    # Any comment blocks that were detached from this element by one or more
    # blank lines.
    #
    # @return [Array<String>]
    def leading_detached_comments
      source_location&.leading_detached_comments&.to_a || []
    end

    # The comments attached to this element, in source order: the leading
    # comment followed by the trailing comment. Absent blocks are omitted.
    #
    # Detached comments are intentionally excluded. Per protoc, they appear
    # before "but [are] not connected to" the element (the author separated
    # them with a blank line), so they are section headers or notes rather
    # than documentation of the element. Access them via
    # {#leading_detached_comments} if needed.
    #
    # @example
    #   field.comments.join("\n").strip
    #
    # @return [Array<String>]
    def comments
      [leading_comments, trailing_comments].compact
    end

    private

    def presence(value)
      value unless value.nil? || value.empty?
    end
  end
end
