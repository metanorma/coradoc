# frozen_string_literal: true

module Coradoc
  module Html
    # Element mapping between CoreModel and HTML elements
    #
    # This module provides bidirectional mapping between CoreModel types
    # and HTML elements for conversion purposes.
    module ElementMapping
      class << self
        # Map CoreModel class to HTML element
        def model_to_html_element(model_class)
          model_name = model_class.name.split('::').last.downcase.to_sym
          MODEL_TO_HTML[model_name] || default_element_for(model_class)
        end

        # Map HTML element to CoreModel class
        def html_element_to_model(tag_name, context = {})
          tag = tag_name.to_s.downcase.to_sym
          HTML_TO_MODEL[tag] || default_model_for(tag, context)
        end

        # Get default element for a model class
        def default_element_for(model_class)
          if model_class.ancestors.any? { |a| a.name&.include?('InlineElement') }
            { tag: 'span', semantic: false }
          else
            { tag: 'div', semantic: false }
          end
        end

        # Get default model for an HTML element
        def default_model_for(tag, _context)
          # Return CoreModel types
          case tag
          when :p, :div, :section, :article
            'Coradoc::CoreModel::Block'
          when :strong, :b, :em, :i, :code
            'Coradoc::CoreModel::InlineElement'
          else
            'Coradoc::CoreModel::InlineElement'
          end
        end

        # Mapping from CoreModel types to HTML elements
        MODEL_TO_HTML = {
          # Document structure
          document: { tag: 'article', semantic: true },
          section: { tag: 'section', semantic: true },
          header: { tag: 'header', semantic: true },
          title: { tag: 'h1', semantic: true },
          structuralelement: { tag: 'section', semantic: true },

          # Block elements
          paragraph: { tag: 'p', semantic: true },
          block: { tag: 'div', semantic: true },
          example: { tag: 'div', class: 'example', semantic: false },
          annotationblock: { tag: 'aside', semantic: true },
          quote: { tag: 'blockquote', semantic: true },
          verse: { tag: 'div', class: 'verse', semantic: false },
          listing: { tag: 'pre', semantic: true },
          literal: { tag: 'pre', semantic: true },
          source: { tag: 'pre', semantic: true },
          open: { tag: 'div', semantic: false },
          pass: { tag: 'div', class: 'pass', semantic: false },

          # Inline elements
          inlineelement: { tag: 'span', semantic: false },
          bold: { tag: 'strong', semantic: true },
          italic: { tag: 'em', semantic: true },
          monospace: { tag: 'code', semantic: true },
          highlight: { tag: 'mark', semantic: true },
          superscript: { tag: 'sup', semantic: true },
          subscript: { tag: 'sub', semantic: true },
          underline: { tag: 'u', semantic: false },
          strikethrough: { tag: 'del', semantic: true },
          smallcaps: { tag: 'span', class: 'small-caps', semantic: false },
          link: { tag: 'a', semantic: true },
          anchor: { tag: 'a', semantic: true },
          xref: { tag: 'a', class: 'xref', semantic: true },
          quotation: { tag: 'q', semantic: true },

          # Lists
          listblock: { tag: 'ul', semantic: true },
          listitem: { tag: 'li', semantic: true },
          orderedlist: { tag: 'ol', semantic: true },
          unorderedlist: { tag: 'ul', semantic: true },

          # Tables
          table: { tag: 'table', semantic: true },
          tablerow: { tag: 'tr', semantic: true },
          tablecell: { tag: 'td', semantic: true },

          # Media
          image: { tag: 'img', semantic: true, self_closing: true },
          video: { tag: 'video', semantic: true },
          audio: { tag: 'audio', semantic: true },

          # Other
          break: { tag: 'hr', semantic: true, self_closing: true },
          linebreak: { tag: 'br', semantic: true, self_closing: true },

          # Text
          textelement: { tag: 'text', semantic: false }
        }.freeze

        # Mapping from HTML elements to CoreModel types
        HTML_TO_MODEL = {
          # Block elements
          p: 'Coradoc::CoreModel::Block',
          div: 'Coradoc::CoreModel::Block',
          section: 'Coradoc::CoreModel::StructuralElement',
          article: 'Coradoc::CoreModel::StructuralElement',
          header: 'Coradoc::CoreModel::StructuralElement',
          aside: 'Coradoc::CoreModel::AnnotationBlock',
          blockquote: 'Coradoc::CoreModel::Block',
          pre: 'Coradoc::CoreModel::Block',

          # Inline elements
          strong: 'Coradoc::CoreModel::InlineElement',
          b: 'Coradoc::CoreModel::InlineElement',
          em: 'Coradoc::CoreModel::InlineElement',
          i: 'Coradoc::CoreModel::InlineElement',
          code: 'Coradoc::CoreModel::InlineElement',
          mark: 'Coradoc::CoreModel::InlineElement',
          sup: 'Coradoc::CoreModel::InlineElement',
          sub: 'Coradoc::CoreModel::InlineElement',
          u: 'Coradoc::CoreModel::InlineElement',
          del: 'Coradoc::CoreModel::InlineElement',
          s: 'Coradoc::CoreModel::InlineElement',
          strike: 'Coradoc::CoreModel::InlineElement',

          # Links
          a: 'Coradoc::CoreModel::InlineElement',

          # Lists
          ul: 'Coradoc::CoreModel::ListBlock',
          ol: 'Coradoc::CoreModel::ListBlock',
          li: 'Coradoc::CoreModel::ListItem',
          dl: 'Coradoc::CoreModel::ListBlock',
          dt: 'Coradoc::CoreModel::ListItem',
          dd: 'Coradoc::CoreModel::ListItem',

          # Tables
          table: 'Coradoc::CoreModel::Table',
          tr: 'Coradoc::CoreModel::TableRow',
          td: 'Coradoc::CoreModel::TableCell',
          th: 'Coradoc::CoreModel::TableCell',

          # Media
          img: 'Coradoc::CoreModel::Image',
          video: 'Coradoc::CoreModel::Block',
          audio: 'Coradoc::CoreModel::Block',

          # Other
          hr: 'Coradoc::CoreModel::Block',
          br: 'Coradoc::CoreModel::InlineElement',

          # Headings
          h1: 'Coradoc::CoreModel::StructuralElement',
          h2: 'Coradoc::CoreModel::StructuralElement',
          h3: 'Coradoc::CoreModel::StructuralElement',
          h4: 'Coradoc::CoreModel::StructuralElement',
          h5: 'Coradoc::CoreModel::StructuralElement',
          h6: 'Coradoc::CoreModel::StructuralElement'
        }.freeze

        # Check if HTML element is block-level
        def block_element?(tag)
          BLOCK_ELEMENTS.include?(tag.to_sym)
        end

        # Check if HTML element is inline-level
        def inline_element?(tag)
          INLINE_ELEMENTS.include?(tag.to_sym)
        end

        # Check if HTML element is self-closing
        def self_closing?(tag)
          SELF_CLOSING_ELEMENTS.include?(tag.to_sym)
        end

        # Block-level HTML elements
        BLOCK_ELEMENTS = %i[
          div p section article aside header footer main nav
          blockquote pre ul ol li dl dt dd
          table tr td th thead tbody tfoot
          h1 h2 h3 h4 h5 h6
          hr
          figure figcaption
        ].freeze

        # Inline-level HTML elements
        INLINE_ELEMENTS = %i[
          span strong em b i u s del ins mark small
          code kbd samp var
          a abbr cite dfn q
          sub sup
          time
          br wbr
        ].freeze

        # Self-closing HTML elements
        SELF_CLOSING_ELEMENTS = %i[
          area base br col embed hr img input link meta param source track wbr
        ].freeze
      end
    end
  end
end
