# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Generic inline formatting element
    #
    # Represents all inline text formatting in AsciiDoc:
    # - Bold (*text* or **text**)
    # - Italic (_text_ or __text__)
    # - Monospace (`text` or ``text``)
    # - Subscript (~text~)
    # - Superscript (^text^)
    # - Underline ([underline]#text#)
    # - Small ([small]#text#)
    # - Links
    # - Cross-references
    # - Footnotes
    #
    # Inline elements can be nested within each other, allowing for
    # complex formatting like bold italic text.
    #
    # @example Simple bold text
    #   bold = CoreModel::InlineElement.new(
    #     format_type: "bold",
    #     constrained: true,
    #     content: "important"
    #   )
    #
    # @example Nested formatting (bold italic)
    #   italic = CoreModel::InlineElement.new(
    #     format_type: "italic",
    #     content: "text"
    #   )
    #   bold = CoreModel::InlineElement.new(
    #     format_type: "bold",
    #     content: "bold ",
    #     nested_elements: [italic]
    #   )
    #
    # @example Unconstrained bold
    #   bold = CoreModel::InlineElement.new(
    #     format_type: "bold",
    #     constrained: false,
    #     content: "word"
    #   )
    class InlineElement < Base
      # @!attribute format_type
      #   @return [String, nil] type of inline formatting
      #     (e.g., 'bold', 'italic', 'monospace', 'link', 'xref')
      attribute :format_type, :string

      # @!attribute constrained
      #   @return [Boolean] whether the formatting uses constrained syntax
      #     (true for *text*, false for **text**)
      attribute :constrained, :boolean, default: -> { true }

      # @!attribute content
      #   @return [String, nil] text content of the element
      attribute :content, :string

      # @!attribute nested_elements
      #   @return [Array<InlineElement>, nil] nested inline formatting
      attribute :nested_elements, InlineElement, collection: true

      # @!attribute target
      #   @return [String, nil] target URL or reference (for links, xrefs)
      attribute :target, :string

      # Mixed content (strings and InlineElement objects)
      # @return [Array] mixed content array
      attr_reader :children

      # Initialize with optional children support
      def initialize(args = {})
        @children = args.delete(:children) || []
        super(args)
      end

      # Set children array
      def children=(value)
        @children = value || []
      end

      # Override to include raw Ruby children attribute in hash output
      def to_hash
        super.tap do |h|
          h['children'] = serialize_children(children) if children&.any?
        end
      end

      private

      # Attributes to compare for semantic equivalence
      #
      # Inline elements are semantically equivalent if they have the same
      # format type, content, and nested elements. The constrained flag
      # affects rendering but not semantic meaning.
      #
      # @return [Array<Symbol>] list of comparable attributes
      def comparable_attributes
        %i[format_type constrained content nested_elements]
      end
    end
  end
end
