# frozen_string_literal: true

module Coradoc
  module CoreModel
    # A single callout annotation attached to a verbatim block.
    #
    # Callouts are the AsciiDoc convention for annotating individual lines
    # of a source/listing block: `<1>` markers appear inside the code and
    # matching `<1> explanation` lines follow the block. Markdown has no
    # native equivalent, so each format gem decides how to render them.
    #
    # The CoreModel stores each annotation as a typed Callout on its parent
    # block, with the in-code marker `<index>` preserved in the block's
    # `content` for verbatim round-trip.
    class Callout < Base
      # @!attribute index
      #   @return [Integer, nil] 1-based callout number matching the
      #     `<N>` marker embedded in the parent block's content.
      attribute :index, :integer

      # @!attribute content
      #   @return [String, nil] human-readable annotation text.
      attribute :content, :string

      private

      def comparable_attributes
        super + %i[index content]
      end
    end
  end
end
