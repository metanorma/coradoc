# frozen_string_literal: true

require 'coradoc/html/node_builder'

module Coradoc
  module Html
    module Converters
      class Section < Base
        class << self
          # Convert HTML <section> to CoreModel::SectionElement
          def to_coradoc(node, state = {})
            title_node = node.at('h1, h2, h3, h4, h5, h6')
            title = title_node&.text&.strip
            level = title_node ? title_node.name[1].to_i : 1

            attrs = extract_node_attributes(node)

            child_nodes = node.children.reject { |child| child.name =~ /^h[1-6]$/ }
            children = child_nodes.flat_map do |child|
              convert_node_to_core(child, state)
            end.compact

            section = Coradoc::CoreModel::SectionElement.new(
              level: level,
              title: title,
              children: children
            )
            section.id = attrs[:id] if attrs[:id]
            section
          end

          # Convert CoreModel::SectionElement to HTML <section>
          def to_html(model, state = {})
            children = []

            if model.title
              level = model.level || 1
              heading_level = [[level + 1, 1].max, 6].min
              heading_attrs = {}
              heading_attrs[:id] = model.id if model.id
              children << NodeBuilder.build("h#{heading_level}", escape_html(model.title), **heading_attrs)
            end

            model.children&.each do |child|
              html = convert_content_to_html(child, state)
              children << html if html && !html.empty?
            end

            section_attrs = {}
            section_attrs[:id] = model.id if model.id && !model.title
            NodeBuilder.build(:section, children, **section_attrs).to_html
          end
        end
      end
    end
  end
end
