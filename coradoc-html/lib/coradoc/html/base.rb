# frozen_string_literal: true

require 'nokogiri'
require 'coradoc/html/node_builder'

module Coradoc
  module Html
    # Base module for HTML processing utilities
    module Base
      VOID_ELEMENTS = %w[area base br col embed hr img input link meta param source track wbr].freeze

      class << self
        # Convert content to HTML, handling various input types
        def convert_content(content, state = {})
          return '' if content.nil?

          case content
          when String
            return '' if content.empty?

            escape_html(content)
          when Array
            return '' if content.empty?

            content.map { |item| convert_content(item, state) }.join
          else
            converter = find_converter(content.class)
            if converter
              converter.to_html(content, state)
            else
              content.to_s
            end
          end
        end

        # Find the appropriate converter for a model class
        def find_converter(model_class)
          return nil unless defined?(Coradoc::Html::Converters)

          converter_name = model_class.name.split('::').last

          begin
            klass = Coradoc::Html::Converters.const_get(converter_name, false)
            return nil if klass == Coradoc::Html::Converters::Base
            return nil unless klass <= Coradoc::Html::Converters::Base

            klass
          rescue NameError
            nil
          end
        end

        # Escape HTML special characters
        def escape_html(text)
          return '' if text.nil?
          return text unless text.is_a?(String)

          text
            .gsub('&', '&amp;')
            .gsub('<', '&lt;')
            .gsub('>', '&gt;')
            .gsub('"', '&quot;')
            .gsub("'", '&#39;')
        end

        # Unescape HTML entities
        def unescape_html(text)
          return '' if text.nil?
          return text unless text.is_a?(String)

          text
            .gsub('&amp;', '&')
            .gsub('&lt;', '<')
            .gsub('&gt;', '>')
            .gsub('&quot;', '"')
            .gsub('&#39;', "'")
            .gsub('&#x27;', "'")
        end

        # Build HTML element with attributes using Nokogiri
        def build_element(tag, content = nil, attributes = {})
          node = NodeBuilder.build(tag, content, **attributes)
          node.to_html
        end

        # Build HTML attributes string using Nokogiri
        def build_attributes(attributes)
          return '' if attributes.nil? || attributes.empty?

          doc = Nokogiri::HTML::DocumentFragment.parse('')
          temp = Nokogiri::XML::Node.new('div', doc)
          attributes.each do |key, value|
            next if value.nil?

            temp[key.to_s] = value.to_s
          end
          attrs_html = temp.to_html
          # Nokogiri gives us <div key="val" ...> — strip the <div> and >
          attrs_html.sub(/^<div/, '').sub(/>$/, '')
        end

        # Check if element is a void element (self-closing)
        def void_element?(tag)
          VOID_ELEMENTS.include?(tag.to_s)
        end

        # Extract attributes from a CoreModel
        def extract_attributes(model)
          attrs = {}

          attrs[:id] = model.id if model.id
          attrs[:title] = model.title if model.title

          if model.is_a?(Coradoc::CoreModel::StructuralElement) && model.metadata
            attrs[:class] = model.metadata[:class] || model.metadata[:role]
            attrs.merge!(model.metadata.except(:class, :role))
          end

          attrs
        end

        # Process children of a node
        def treat_children(children, state = {})
          return [] if children.nil? || children.empty?

          Array(children).map do |child|
            convert_content(child, state)
          end
        end
      end
    end
  end
end
