# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      # Caption only appears as a Figure child. If encountered standalone,
      # extract its text as an inline element so it isn't lost.
      class Caption < Base
        def build(node)
          CoreModel::InlineElement.new(content: extract_text(node))
        end
      end
    end
  end
end
