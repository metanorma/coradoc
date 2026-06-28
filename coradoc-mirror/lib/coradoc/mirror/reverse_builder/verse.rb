# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Verse < Base
        def build(node)
          CoreModel::VerseBlock.new(
            content: extract_text(node),
            attribution: node.attrs&.attribution
          )
        end
      end
    end
  end
end
