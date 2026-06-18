# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    # Sidebar block — a tangential aside, visually distinct from main flow.
    #
    # Markdown has no native sidebar. Serialized as an HTML fallback:
    #   <div class="sidebar">...</div>
    class Sidebar < Base
      attribute :content, :string
      attribute :title, :string

      def initialize(content:, title: nil, **rest)
        super
        @content = content
        @title = title
      end
    end
  end
end
