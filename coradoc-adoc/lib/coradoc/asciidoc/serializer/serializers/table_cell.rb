# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class TableCell < Base
          def to_adoc(model, _options = {})
            @model = model
            _anchor = @model.gen_anchor(inline: true)

            # Handle content - if it's a single string, strip unicode; otherwise serialize children
            if @model.content.is_a?(String)
              _content = Coradoc.strip_unicode(@model.content) if defined?(Coradoc.strip_unicode)
              _content ||= @model.content
            elsif @model.content.is_a?(Array) && @model.content.size == 1 && @model.content.first.is_a?(String)
              _content = Coradoc.strip_unicode(@model.content.first) if defined?(Coradoc.strip_unicode)
              _content ||= @model.content.first.to_s
            else
              _content = serialize_children(@model.content)
            end

            # Build format specification: [colspan][.rowspan][halign][valign][style][*]
            format_spec = build_format_specification

            "#{format_spec}| #{_anchor}#{_content}"
          end

          private

          # Build AsciiDoc cell format specification
          # Format: [colspan][.rowspan][halign][valign][style][*]
          def build_format_specification
            spec = ''

            # Colspan (digits)
            spec += @model.colspan.to_s if @model.colspan && @model.colspan > 1

            # Rowspan (.digits)
            spec += ".#{@model.rowspan}" if @model.rowspan && @model.rowspan > 1

            # Horizontal alignment (< ^ >)
            spec += @model.halign if @model.halign && %w[< ^ >].include?(@model.halign)

            # Vertical alignment (.< .^ .>)
            spec += ".#{@model.valign}" if @model.valign && %w[< ^ >].include?(@model.valign)

            # Style (d s e m a l v)
            spec += @model.style if @model.style && %w[d s e m a l v].include?(@model.style)

            # Repeat marker
            spec += '*' if @model.repeat

            # Fall back to legacy attributes if new attributes are empty
            spec = build_legacy_format_spec if spec.empty? && (@model.colrowattr || @model.alignattr || @model.style)

            spec
          end

          # Build format spec from legacy attributes (backward compatibility)
          def build_legacy_format_spec
            spec = ''
            spec += @model.colrowattr.to_s
            spec += @model.alignattr.to_s
            # NOTE: style was included in colrowattr in old format
            spec
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::TableCell, Serializers::TableCell)
    end
  end
end
