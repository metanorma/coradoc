# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Blockquote < Base
          def to_coradoc(node, state = {})
            id = node['id']
            cite = node['cite']
            content = treat_children_coradoc(node, state)

            Coradoc::CoreModel::Block.new(
              delimiter_type: '____',
              content: content,
              id: id,
              metadata: cite ? { attribution: cite } : {}
            )
          end
        end

        register :blockquote, Blockquote.new
      end
    end
  end
end
