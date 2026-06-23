# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    # Sidebar block — a tangential aside, visually distinct from main flow.
    #
    # Markdown has no native sidebar. Serialized as a VitePress `:::info`
    # custom container. When the sidebar contains structured children
    # (code blocks, lists, etc.), they are rendered into the container.
    class Sidebar < Base
      attribute :content, :string
      attribute :title, :string
      attribute :children, Coradoc::Markdown::Base, collection: true, default: []

      def initialize(content:, title: nil, children: [], **rest)
        super
        @content = content
        @title = title
        @children = Array(children)
      end
    end
  end
end
