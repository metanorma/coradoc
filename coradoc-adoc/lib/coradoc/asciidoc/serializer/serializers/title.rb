# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Title < Base
          def to_adoc(model, options_or_context = {})
            context = normalize_context(options_or_context)
            @model = model
            _anchor = model.anchor.nil? ? '' : "#{serialize_child(model.anchor, context)}\n"
            _content = serialize_children(model.content, context)

            # For ATX style headings, use # markers
            if model.style == 'atx'
              atx_markers = '#' * (model.level_int + 1)
              "#{_anchor}#{atx_markers} #{_content}#{model.line_break}"
            else
              # Default setext style
              "#{_anchor}#{style_str}#{level_str} #{_content}#{model.line_break}"
            end
          end

          private

          def level_str
            return '' if @model.level_int.nil?

            if @model.level_int <= 5
              '=' * (@model.level_int + 1)
            else
              '======'
            end
          end

          def style_str
            return '' if @model.level_int.nil?

            # Don't include style in output for atx since it's implicit
            return '' if @model.style == 'atx'

            _style = [@model.style].compact.reject { |s| s == 'atx' }
            _style << "level=#{@model.level_int}" if @model.level_int > 5
            _style = _style.join(',')

            _style.empty? ? '' : "[#{_style}]\n"
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Title, Serializers::Title)
    end
  end
end
