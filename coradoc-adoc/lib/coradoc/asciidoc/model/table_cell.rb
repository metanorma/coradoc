# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Table cell with full AsciiDoc format specification support
      #
      # Cell format specification: [colspan][.rowspan][halign][valign][style][*]
      #
      # @!attribute [r] id
      #   @return [String, nil] Optional cell identifier
      # @!attribute [r] content
      #   @return [Array<TextElement>] Cell content
      # @!attribute [r] colspan
      #   @return [Integer, nil] Number of columns to span
      # @!attribute [r] rowspan
      #   @return [Integer, nil] Number of rows to span
      # @!attribute [r] halign
      #   @return [String, nil] Horizontal alignment: "<" left, "^" center, ">" right
      # @!attribute [r] valign
      #   @return [String, nil] Vertical alignment: "<" top, "^" middle, ">" bottom
      # @!attribute [r] style
      #   @return [String, nil] Cell style: d/s/e/m/a/l/v
      # @!attribute [r] repeat
      #   @return [Boolean] Whether to repeat last cell
      # @!attribute [r] colrowattr
      #   @return [String] Legacy combined colspan.rowspan string (for serialization)
      # @!attribute [r] alignattr
      #   @return [String] Legacy alignment string (for serialization)
      #
      # @example Cell spanning 2 columns
      #   cell = TableCell.new(content: "text", colspan: 2)
      #
      # @example Centered cell with emphasis style
      #   cell = TableCell.new(content: "text", halign: "^", style: "e")
      #
      class TableCell < Base
        include Coradoc::AsciiDoc::Model::Anchorable

        # Core attributes
        attribute :id, :string
        attribute :content, Coradoc::AsciiDoc::Model::TextElement, collection: true, initialize_empty: true

        # Cell format specification attributes
        attribute :colspan, :integer
        attribute :rowspan, :integer
        attribute :halign, :string  # "<" left, "^" center, ">" right
        attribute :valign, :string  # "<" top, "^" middle, ">" bottom
        attribute :style, :string   # d/s/e/m/a/l/v
        attribute :repeat, :boolean, default: -> { false }

        # Legacy attributes for backward compatibility with serializer
        attribute :colrowattr, :string, default: -> { '' }
        attribute :alignattr, :string, default: -> { '' }

        # Check if this cell contains AsciiDoc content
        def asciidoc?
          style == 'a'
        end

        # Check if this cell has literal content
        def literal?
          style == 'l'
        end

        # Check if this cell has verse style
        def verse?
          style == 'v'
        end

        # Get horizontal alignment as CSS value
        # @return [String, nil] "left", "center", or "right"
        def horizontal_alignment
          case halign
          when '<' then 'left'
          when '^' then 'center'
          when '>' then 'right'
          end
        end

        # Get vertical alignment as CSS value
        # @return [String, nil] "top", "middle", or "bottom"
        def vertical_alignment
          case valign
          when '<' then 'top'
          when '^' then 'middle'
          when '>' then 'bottom'
          end
        end

        # Get style name as human-readable string
        # @return [String, nil] Style name
        def style_name
          case style
          when 'd' then 'default'
          when 's' then 'strong'
          when 'e' then 'emphasis'
          when 'm' then 'monospace'
          when 'a' then 'asciidoc'
          when 'l' then 'literal'
          when 'v' then 'verse'
          end
        end

        # Generate colrowattr for serialization (e.g., "2.3" for colspan=2, rowspan=3)
        # @return [String] Combined colspan.rowspan string
        def generate_colrowattr
          result = ''
          result += colspan.to_s if colspan && colspan > 1
          result += ".#{rowspan}" if rowspan && rowspan > 1
          result
        end

        # Generate alignattr for serialization (e.g., "^" for center)
        # @return [String] Combined alignment string
        def generate_alignattr
          (halign || '') + (valign || '')
        end
      end
    end
  end
end
