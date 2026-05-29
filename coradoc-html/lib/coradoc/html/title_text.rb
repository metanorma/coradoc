# frozen_string_literal: true

module Coradoc
  module Html
    # Resolves CoreModel title attributes to plain-text strings.
    #
    # CoreModel titles can be String, CoreModel::Base (with .text),
    # Array of mixed types, or nil. This utility provides a single
    # resolution path used by TocBuilder, TocSerializer, Renderer,
    # LayoutRenderer, and Drop classes.
    module TitleText
      TEXT_TYPES = [CoreModel::TextContent, CoreModel::Term].freeze

      module_function

      def resolve(title)
        case title
        when nil then nil
        when String then title
        when CoreModel::Base then resolve_model(title)
        when Array then title.map { |t| resolve_element(t) }.join
        else title.to_s
        end
      end

      def escape(title)
        resolved = resolve(title)
        resolved ? Escape.escape_html(resolved) : nil
      end

      def resolve_model(model)
        if text_type?(model) && model.text
          model.text
        elsif content_type?(model) && model.content
          model.content.to_s
        else
          model.to_s
        end
      end

      def resolve_element(element)
        case element
        when CoreModel::Base then resolve_model(element)
        else element.to_s
        end
      end

      def text_type?(model)
        TEXT_TYPES.any? { |t| model.is_a?(t) }
      end

      def content_type?(model)
        model.is_a?(CoreModel::InlineElement) || model.is_a?(CoreModel::StructuralElement)
      end
    end
  end
end
