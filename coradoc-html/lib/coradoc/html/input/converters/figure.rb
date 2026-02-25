# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Figure < Base
          def to_coradoc(node, state = {})
            id = node['id']
            title_content = extract_title(node)
            content = treat_children_coradoc(node, state)

            # Use CoreModel::Block with delimiter_type "====" for example/figure
            Coradoc::CoreModel::Block.new(
              delimiter_type: '====',
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

          # Extract text from content array
          def extract_text_from_content(content)
            return content if content.is_a?(String)
            return '' if content.nil?

            content.map do |item|
              case item
              when String
                item
              when Coradoc::CoreModel::InlineElement
                item.content.to_s
              when Coradoc::CoreModel::Base
                if item.respond_to?(:content)
                  item.content.to_s
                elsif item.respond_to?(:title)
                  item.title.to_s
                else
                  ''
                end
              else
                item.to_s
              end
            end.join
          end
        end

        register :figure, Figure.new
      end
    end
  end
end
