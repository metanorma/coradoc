# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Aside < Base
          INSTANCE = new

          def to_coradoc(node, state = {})
            content = treat_children_coradoc(node, state)
            Coradoc::CoreModel::SidebarBlock.new(
              children: content
            )
          end
        end

        register :aside, Aside::INSTANCE
      end
    end
  end
end
