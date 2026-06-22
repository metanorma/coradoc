# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    # Example block — an illustrative container, optionally with a caption.
    #
    # Markdown has no native example syntax. Default rendering is an
    # HTML fallback that preserves the caption as an `<h4>` heading
    # inside a `<div class="example">` wrapper.
    #
    # When `admonition_style == :container` (VitePress), the serializer
    # emits `:::details Caption\n...\n:::`.
    class ExampleBlock < Base
      attribute :content, :string
      attribute :caption, :string
      attribute :children, Coradoc::Markdown::Base, collection: true, default: []

      def initialize(content:, caption: nil, children: [], **rest)
        super
        @content = content
        @caption = caption
        @children = Array(children)
      end
    end
  end
end
