# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Generic inline formatting element
    #
    # Typed subclasses (BoldElement, ItalicElement, etc.) express their
    # format identity via the class hierarchy — the class IS the format type.
    # Generic InlineElement instances use the format_type attribute for typing.
    class InlineElement < Base
      attribute :children, Base, collection: true

      include ChildrenContent

      def self.format_type
        nil
      end

      def self.format_type_class(type)
        FORMAT_TYPE_CLASS_MAP[type] || InlineElement
      end

      def resolve_format_type
        self.class.format_type || format_type
      end

      FORMAT_TYPES = %w[
        bold italic monospace underline strikethrough
        subscript superscript highlight
        link xref stem footnote
        hard_line_break text span term
        line_break quotation
      ].freeze

      attribute :format_type, :string
      attribute :content, :string
      attribute :nested_elements, InlineElement, collection: true
      attribute :target, :string
      attribute :stem_type, :string

      private

      def comparable_attributes
        %i[format_type content nested_elements stem_type]
      end
    end

    # Typed InlineElement subclasses

    class BoldElement < InlineElement
      def self.format_type
        'bold'
      end
    end

    class ItalicElement < InlineElement
      def self.format_type
        'italic'
      end
    end

    class MonospaceElement < InlineElement
      def self.format_type
        'monospace'
      end
    end

    class UnderlineElement < InlineElement
      def self.format_type
        'underline'
      end
    end

    class StrikethroughElement < InlineElement
      def self.format_type
        'strikethrough'
      end
    end

    class SubscriptElement < InlineElement
      def self.format_type
        'subscript'
      end
    end

    class SuperscriptElement < InlineElement
      def self.format_type
        'superscript'
      end
    end

    class HighlightElement < InlineElement
      def self.format_type
        'highlight'
      end
    end

    class LinkElement < InlineElement
      def self.format_type
        'link'
      end
    end

    class CrossReferenceElement < InlineElement
      def self.format_type
        'xref'
      end
    end

    class StemElement < InlineElement
      def self.format_type
        'stem'
      end
    end

    class FootnoteElement < InlineElement
      def self.format_type
        'footnote'
      end
    end

    class HardLineBreakElement < InlineElement
      def self.format_type
        'hard_line_break'
      end
    end

    class TextElement < InlineElement
      def self.format_type
        'text'
      end
    end

    class SpanElement < InlineElement
      def self.format_type
        'span'
      end
    end

    class TermElement < InlineElement
      def self.format_type
        'term'
      end
    end

    class LineBreakElement < InlineElement
      def self.format_type
        'line_break'
      end
    end

    FORMAT_TYPE_CLASS_MAP = {
      'bold' => BoldElement,
      'italic' => ItalicElement,
      'monospace' => MonospaceElement,
      'underline' => UnderlineElement,
      'strikethrough' => StrikethroughElement,
      'subscript' => SubscriptElement,
      'superscript' => SuperscriptElement,
      'highlight' => HighlightElement,
      'link' => LinkElement,
      'xref' => CrossReferenceElement,
      'stem' => StemElement,
      'footnote' => FootnoteElement,
      'hard_line_break' => HardLineBreakElement,
      'text' => TextElement,
      'span' => SpanElement,
      'term' => TermElement,
      'line_break' => LineBreakElement
    }.freeze
  end
end
