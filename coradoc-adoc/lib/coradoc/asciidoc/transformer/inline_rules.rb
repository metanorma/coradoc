# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Module containing inline element transformation rules
      module InlineRules
        # Inline formatting variants that share the same rule shape:
        # constrained and unconstrained forms of the same model class.
        # `span` is excluded because it carries `text:` + `attributes:`
        # rather than `content:`, so it gets its own pair of rules.
        FORMATTING_VARIANTS = [
          %i[bold Bold],
          %i[italic Italic],
          %i[highlight Highlight],
          %i[monospace Monospace]
        ].freeze

        def self.apply(transformer_class)
          transformer_class.class_eval do
            # Link
            rule(link: subtree(:link)) do
              Model::Inline::Link.new(
                path: link[:path].to_s,
                name: link[:text]&.to_s
              )
            end

            # Cross reference
            rule(cross_reference: subtree(:xref)) do
              href = xref[:href].to_s
              text = xref[:text]
              args = text ? [text.to_s] : []
              Model::Inline::CrossReference.new(
                href:, args:
              )
            end

            # Inline image
            rule(inline_image: subtree(:inline_image)) do
              attrs = AttributeListNormalizer.coerce(inline_image[:attribute_list])
              promoted, residual = Model::Image::AttributeExtractor.call(
                attrs, Model::Image::InlineImage
              )
              Model::Image::InlineImage.new(
                src: inline_image[:path],
                attributes: residual,
                **promoted
              )
            end

            # Inline passthrough (`+++raw content+++` or `pass:[raw]`).
            # Both forms carry an opaque payload that survives all
            # substitutions verbatim; `form` records which syntax was
            # used so the AsciiDoc serializer can round-trip faithfully.
            rule(inline_passthrough: subtree(:passthrough)) do
              Model::Inline::Passthrough.new(
                content: passthrough[:raw].to_s,
                form: 'triple'
              )
            end

            # Attribute reference
            rule(attribute_reference: simple(:name)) do
              Model::Inline::AttributeReference.new(
                name:
              )
            end

            # Hard line break (` +\n` or `\\n`). Emitted as a dedicated
            # AsciiDoc model (Inline::HardLineBreak) distinct from
            # Model::LineBreak, which only represents paragraph-separator
            # blank lines. Hard breaks carry semantic meaning: HTML/Markdown
            # renderers map them to <br>.
            rule(hard_line_break: simple(:hard_line_break)) do
              Model::Inline::HardLineBreak.new
            end

            # Term
            rule(
              term_type: simple(:term_type),
              term: simple(:term)
            ) do
              Coradoc::AsciiDoc::Model::Term.new(
                term:, type: term_type, lang: :en
              )
            end

            # Footnote
            rule(footnote: simple(:footnote)) do
              text_str = footnote.to_s
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(
                text: text_str
              )
            end

            rule(footnote: simple(:footnote), id: simple(:id)) do
              text_str = footnote.to_s
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(
                text: text_str, id: id.to_s
              )
            end

            # Footnote with empty content (reference to named footnote)
            rule(footnote: sequence(:footnote), id: simple(:id)) do
              text_str = footnote.map(&:to_s).join
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(
                text: text_str, id: id.to_s
              )
            end

            # Footnote with empty content and no id
            rule(footnote: sequence(:footnote)) do
              text_str = footnote.map(&:to_s).join
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(
                text: text_str
              )
            end

            # Inline formatting rules generated from a single registry.
            # See InlineRules::FORMATTING_VARIANTS. `span` is special
            # because it carries `text:` + `attributes:` rather than
            # `content:`, so it stays inline below.
            InlineRules::FORMATTING_VARIANTS.each do |prefix, class_name|
              klass = Model::Inline.const_get(class_name)
              constrained_key = :"#{prefix}_constrained"
              unconstrained_key = :"#{prefix}_unconstrained"

              rule(constrained_key => subtree(:subtree)) do
                content = Transformer.extract_inline_content(subtree)
                klass.new(
                  content: content, unconstrained: false
                )
              end
              rule(unconstrained_key => subtree(:subtree)) do
                content = Transformer.extract_inline_content(subtree)
                klass.new(
                  content: content, unconstrained: true
                )
              end
            end

            # Span (constrained)
            rule(span_constrained: subtree(:span_constrained)) do
              Model::Inline::Span.new(
                text: span_constrained[:text],
                unconstrained: false,
                attributes: span_constrained[:attribute_list]
              )
            end

            # Span (unconstrained)
            rule(span_unconstrained: subtree(:span_unconstrained)) do
              Model::Inline::Span.new(
                text: span_unconstrained[:text],
                unconstrained: true,
                attributes: span_unconstrained[:attribute_list]
              )
            end

            # Superscript
            rule(superscript: subtree(:superscript)) do
              content = Transformer.extract_simple_inline_content(superscript)
              Model::Inline::Superscript.new(
                content:
              )
            end

            # Subscript
            rule(subscript: subtree(:subscript)) do
              content = Transformer.extract_simple_inline_content(subscript)
              Model::Inline::Subscript.new(
                content:
              )
            end

            # Highlight (simple)
            rule(highlight: simple(:text)) do
              Model::Highlight.new(
                content: text
              )
            end
            # Stem
            rule(stem: subtree(:stem)) do
              Coradoc::AsciiDoc::Model::Inline::Stem.new(
                type: stem[:stem_type],
                content: stem[:content]
              )
            end
          end
        end
      end
    end
  end
end
