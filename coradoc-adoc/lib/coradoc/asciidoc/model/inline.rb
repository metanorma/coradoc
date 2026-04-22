# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Autoload inline elements lazily
        autoload :Base, 'coradoc/asciidoc/model/inline/base'
        autoload :Anchor, 'coradoc/asciidoc/model/inline/anchor'
        autoload :AttributeReference, 'coradoc/asciidoc/model/inline/attribute_reference'
        autoload :Bold, 'coradoc/asciidoc/model/inline/bold'
        autoload :Italic, 'coradoc/asciidoc/model/inline/italic'
        autoload :CrossReference, 'coradoc/asciidoc/model/inline/cross_reference'
        autoload :CrossReferenceArg, 'coradoc/asciidoc/model/inline/cross_reference_arg'
        autoload :Monospace, 'coradoc/asciidoc/model/inline/monospace'
        autoload :Link, 'coradoc/asciidoc/model/inline/link'
        autoload :Quotation, 'coradoc/asciidoc/model/inline/quotation'
        autoload :Highlight, 'coradoc/asciidoc/model/inline/highlight'
        autoload :Subscript, 'coradoc/asciidoc/model/inline/subscript'
        autoload :Superscript, 'coradoc/asciidoc/model/inline/superscript'
        autoload :HardLineBreak, 'coradoc/asciidoc/model/inline/hard_line_break'
        autoload :Span, 'coradoc/asciidoc/model/inline/span'
        autoload :Footnote, 'coradoc/asciidoc/model/inline/footnote'
        autoload :Underline, 'coradoc/asciidoc/model/inline/underline'
        autoload :Small, 'coradoc/asciidoc/model/inline/small'
        autoload :Strikethrough, 'coradoc/asciidoc/model/inline/strikethrough'
        autoload :Stem, 'coradoc/asciidoc/model/inline/stem'
      end
    end
  end
end
