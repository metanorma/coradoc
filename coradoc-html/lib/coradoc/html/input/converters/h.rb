# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class H < Base
          def to_coradoc(node, state = {})
            id = node['id']
            internal_anchor = treat_children_anchors(node, state)

            # Check if it has id attribute
            if id.to_s.empty? && internal_anchor.size.positive?
              first_model = internal_anchor.first
              # InlineElement (anchor) has a target attribute
              id = first_model.target if first_model.is_a?(Coradoc::CoreModel::InlineElement) && first_model.target
            end

            level_int = node.name[/\d/].to_i
            content = treat_children_no_anchors(node, state)

            Coradoc::CoreModel::StructuralElement.new(
              element_type: 'section',
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
            return '' if content.nil? || content.empty?

            # Extract text from content
            if content.is_a?(Array)
              content.map do |c|
                if c.is_a?(Coradoc::CoreModel::InlineElement)
                  c.content.to_s
                else
                  c.to_s
                end
              end.join.strip
            elsif content.is_a?(Coradoc::CoreModel::InlineElement)
              content.content.to_s
            else
              content.to_s
            end
          end
        end

        register :h1, H.new
        register :h2, H.new
        register :h3, H.new
        register :h4, H.new
        register :h5, H.new
        register :h6, H.new
      end
    end
  end
end
