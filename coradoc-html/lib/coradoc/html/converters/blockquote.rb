# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Blockquote < Base
        INSTANCE = new

        def to_coradoc(node, state = {})
          id = node['id']
          cite = node['cite']
          content = treat_children_coradoc(node, state)

          Coradoc::CoreModel::QuoteBlock.new(
            children: content,
            id: id,
            attribution: cite
          )
        end
      end

      register :blockquote, Blockquote::INSTANCE
    end
  end
end
