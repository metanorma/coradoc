# frozen_string_literal: true

module Coradoc
  module Markdown
    module Transform
      module ListTransformer
        class << self
          def transform_list(list)
            items = Array(list.items).map do |item|
              transform_list_item(item)
            end

            Coradoc::Markdown::List.new(
              ordered: list.marker_type == 'ordered',
              items: items
            )
          end

          def transform_list_item(item)
            content = item.renderable_content
            has_structured = content.is_a?(Array) && content.any? do |c|
              !c.is_a?(CoreModel::TextContent)
            end
            if has_structured
              children = content.map { |c| BlockTransformer.transform_content_node(c) }
              Coradoc::Markdown::ListItem.new(text: item.flat_text, children: children)
            else
              Coradoc::Markdown::ListItem.new(text: item.flat_text)
            end
          end

          def transform_definition_list(dl)
            items = Array(dl.items).map do |item|
              definitions = Array(item.definitions).map do |defn|
                Coradoc::Markdown::DefinitionItem.new(content: defn.to_s)
              end
              Coradoc::Markdown::DefinitionTerm.new(
                text: item.term.to_s,
                definitions: definitions
              )
            end

            Coradoc::Markdown::DefinitionList.new(items: items)
          end
        end

        FromCoreModel.register(CoreModel::ListBlock, method(:transform_list))
        FromCoreModel.register(CoreModel::DefinitionList, method(:transform_definition_list))
      end
    end
  end
end
