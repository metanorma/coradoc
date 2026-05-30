# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Figure < Base
          INSTANCE = new

          def to_coradoc(node, state = {})
            id = node['id']
            title_content = extract_title(node)
            content = treat_children_coradoc(node, state)

            # Use CoreModel::ExampleBlock for example/figure
            Coradoc::CoreModel::ExampleBlock.new(
              title: extract_text_from_content(title_content),
              children: content,
              id: id
            )
          end

          def extract_title(node)
            title = node.at('./figcaption')
            return '' if title.nil?

            treat_children_coradoc(title, {})
          end
        end

        register :figure, Figure::INSTANCE
      end
    end
  end
end
