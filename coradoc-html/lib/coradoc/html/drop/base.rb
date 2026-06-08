# frozen_string_literal: true

require 'liquid'

module Coradoc
  module Html
    module Drop
      class Base < Liquid::Drop
        attr_reader :model

        def initialize(model)
          @model = model
        end

        def to_liquid
          self
        end

        def template_type
          self.class.name
              .split('::').last
              .sub(/Drop$/, '')
              .gsub(/([A-Z])/, '_\1')
              .downcase
              .sub(/^_/, '')
        end

        def id
          @model.id
        end

        def title
          optional_text(@model.title)
        end

        protected

        def optional_text(value)
          return nil unless value && !value.to_s.empty?

          Escape.escape_html(value)
        end

        def extract_text(content)
          case content
          when nil then ''
          when String then content
          when Array then content.map { |c| extract_text(c) }.join
          when CoreModel::InlineElement
            content.text || extract_text(content.content)
          when CoreModel::TextContent
            content.text.to_s
          when CoreModel::Base
            TitleText.resolve(content).to_s
          else
            content.to_s
          end
        end

        def content_to_liquid(content)
          DropFactory.create(content)
        end

        def children_to_liquid(children)
          return [] unless children

          children.map { |child| DropFactory.create(child) }
        end
      end
    end
  end
end
