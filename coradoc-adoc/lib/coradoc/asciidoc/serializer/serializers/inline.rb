# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload inline serializers
        module Inline
          autoload :Anchor, 'coradoc/asciidoc/serializer/serializers/inline/anchor'
          autoload :AttributeReference, 'coradoc/asciidoc/serializer/serializers/inline/attribute_reference'
          autoload :Bold, 'coradoc/asciidoc/serializer/serializers/inline/bold'
          autoload :CrossReference, 'coradoc/asciidoc/serializer/serializers/inline/cross_reference'
          autoload :CrossReferenceArg, 'coradoc/asciidoc/serializer/serializers/inline/cross_reference_arg'
          autoload :Footnote, 'coradoc/asciidoc/serializer/serializers/inline/footnote'
          autoload :HardLineBreak, 'coradoc/asciidoc/serializer/serializers/inline/hard_line_break'
          autoload :Highlight, 'coradoc/asciidoc/serializer/serializers/inline/highlight'
          autoload :Italic, 'coradoc/asciidoc/serializer/serializers/inline/italic'
          autoload :Link, 'coradoc/asciidoc/serializer/serializers/inline/link'
          autoload :Monospace, 'coradoc/asciidoc/serializer/serializers/inline/monospace'
          autoload :Quotation, 'coradoc/asciidoc/serializer/serializers/inline/quotation'
          autoload :Small, 'coradoc/asciidoc/serializer/serializers/inline/small'
          autoload :Span, 'coradoc/asciidoc/serializer/serializers/inline/span'
          autoload :Stem, 'coradoc/asciidoc/serializer/serializers/inline/stem'
          autoload :Strikethrough, 'coradoc/asciidoc/serializer/serializers/inline/strikethrough'
          autoload :Subscript, 'coradoc/asciidoc/serializer/serializers/inline/subscript'
          autoload :Superscript, 'coradoc/asciidoc/serializer/serializers/inline/superscript'
          autoload :Underline, 'coradoc/asciidoc/serializer/serializers/inline/underline'
        end
      end
    end
  end
end
