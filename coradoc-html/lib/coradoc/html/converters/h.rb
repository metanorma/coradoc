# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class H < Base
        INSTANCE = new

        def to_coradoc(node, state = {})
          id = node['id']
          internal_anchor = treat_children_anchors(node, state)

          if id.to_s.empty? && internal_anchor.size.positive?
            first_model = internal_anchor.first
            id = first_model.target if first_model.is_a?(Coradoc::CoreModel::InlineElement) && first_model.target
          end

          level_int = node.name[/\d/].to_i
          content = treat_children_no_anchors(node, state)

          Coradoc::CoreModel::SectionElement.new(
            title: extract_title_text(content),
            level: level_int,
            id: id,
            children: []
          )
        end

        def treat_children_no_anchors(node, state)
          node.children.reject { |a| a.name == 'a' }
              .map do |child|
            treat_coradoc(child, state)
          end.flatten.compact
        end

        def treat_children_anchors(node, state)
          node.children.select { |a| a.name == 'a' }
              .map do |child|
            treat_coradoc(child, state)
          end.flatten.compact
        end

        private

        def extract_title_text(content)
          Coradoc::CoreModel::InlineContent.text_of(content).strip
        end
      end

      register :h1, H::INSTANCE
      register :h2, H::INSTANCE
      register :h3, H::INSTANCE
      register :h4, H::INSTANCE
      register :h5, H::INSTANCE
      register :h6, H::INSTANCE
    end
  end
end
