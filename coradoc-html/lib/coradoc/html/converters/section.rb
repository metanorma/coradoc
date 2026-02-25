# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Section structural element
      class Section < Base
        class << self
          # Convert HTML <section> to CoreModel::StructuralElement
          # @param node [Nokogiri::XML::Node] HTML section node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::StructuralElement] Section model
          def to_coradoc(node, state = {})
            # Extract section title from heading
            title_node = node.at('h1, h2, h3, h4, h5, h6')
            title = title_node&.text&.strip
            level = title_node ? title_node.name[1].to_i : 1

            # Extract attributes
            attrs = extract_node_attributes(node)

            # Process children (skip the heading as we already extracted it)
            child_nodes = node.children.reject { |child| child.name =~ /^h[1-6]$/ }
            children = child_nodes.flat_map do |child|
              convert_node_to_core(child, state)
            end.compact

            # Create CoreModel section
            section = Coradoc::CoreModel::StructuralElement.new(
              element_type: 'section',
              level: level,
              title: title,
              children: children
            )

            # Set ID if present
            section.id = attrs[:id] if attrs[:id]

            section
          end

          # Convert CoreModel::StructuralElement to HTML <section>
          # @param model [Coradoc::CoreModel::StructuralElement] Section model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            parts = []

            # Add title as heading
            if model.title
              # Calculate heading level (level 0 -> h1, level 1 -> h2, etc.)
              level = model.level || 1
              heading_level = [[level + 1, 1].max, 6].min # Clamp between h1-h6
              heading_tag = "h#{heading_level}"

              title_text = escape_html(model.title)

              title_attrs = {}
              title_attrs[:id] = model.id if model.id

              parts << build_element(heading_tag, title_text, title_attrs)
            end

            # Add section children (paragraphs, lists, nested sections, etc.)
            model.children&.each do |child|
              parts << convert_content_to_html(child, state)
            end

            # Wrap in section tag
            content = parts.join("\n")
            attributes = extract_section_attributes(model)
            build_element('section', content, attributes)
          end

          private

          # Extract section-level attributes
          def extract_section_attributes(model)
            attrs = {}

            # Don't duplicate ID if already on heading
            attrs[:id] = model.id if !(model.title && model.id) && model.id

            attrs
          end
        end
      end
    end
  end
end
