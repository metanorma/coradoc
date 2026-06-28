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
          %i[bold      Bold],
          %i[italic    Italic],
          %i[highlight Highlight],
          %i[monospace Monospace]
        ].freeze

        def self.apply(transformer_class)
          transformer_class.class_eval do
            # Link
            rule(link: subtree(:link)) do
              Model::Inline::Link.new(
                path: link[:path].to_s,
                name: link[:text]&.to_s,
                source_line: SourceLineExtractor.extract(link)
              )
            end

            # Cross reference
            rule(cross_reference: subtree(:xref)) do
              href = xref[:href].to_s
              text = xref[:text]
              args = text ? [text.to_s] : []
              Model::Inline::CrossReference.new(
                href:, args:,
                source_line: SourceLineExtractor.extract(xref)
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
                source_line: SourceLineExtractor.extract(inline_image),
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
                form: 'triple',
                source_line: SourceLineExtractor.extract(passthrough)
              )
            end

            # Attribute reference
            rule(attribute_reference: simple(:name)) do
              Model::Inline::AttributeReference.new(
                name:,
                source_line: SourceLineExtractor.extract(name)
              )
            end

            # Hard line break (` +\n` or `\\n`). Emitted as a dedicated
            # AsciiDoc model (Inline::HardLineBreak) distinct from
            # Model::LineBreak, which only represents paragraph-separator
            # blank lines. Hard breaks carry semantic meaning: HTML/Markdown
            # renderers map them to <br>.
            rule(hard_line_break: simple(:hard_line_break)) do
              Model::Inline::HardLineBreak.new(
                source_line: SourceLineExtractor.extract(hard_line_break)
              )
            end

            # Term
            rule(
              term_type: simple(:term_type),
              term: simple(:term)
            ) do
              Coradoc::AsciiDoc::Model::Term.new(
                term:, type: term_type, lang: :en,
                source_line: SourceLineExtractor.extract(term_type)
              )
            end

            # Footnote
            rule(footnote: simple(:footnote)) do
              text_str = footnote.to_s
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(
                text: text_str,
                source_line: SourceLineExtractor.extract(footnote)
              )
            end

            rule(footnote: simple(:footnote), id: simple(:id)) do
              text_str = footnote.to_s
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(
                text: text_str, id: id.to_s,
                source_line: SourceLineExtractor.extract(footnote)
              )
            end

            # Footnote with empty content (reference to named footnote)
            rule(footnote: sequence(:footnote), id: simple(:id)) do
              text_str = footnote.map(&:to_s).join
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(
                text: text_str, id: id.to_s,
                source_line: SourceLineExtractor.extract(footnote)
              )
            end

            # Footnote with empty content and no id
            rule(footnote: sequence(:footnote)) do
              text_str = footnote.map(&:to_s).join
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(
                text: text_str,
                source_line: SourceLineExtractor.extract(footnote)
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
                  content: content, unconstrained: false,
                  source_line: SourceLineExtractor.extract(subtree)
                )
              end
              rule(unconstrained_key => subtree(:subtree)) do
                content = Transformer.extract_inline_content(subtree)
                klass.new(
                  content: content, unconstrained: true,
                  source_line: SourceLineExtractor.extract(subtree)
                )
              end
            end

            # Span (constrained)
            rule(span_constrained: subtree(:span_constrained)) do
              Model::Inline::Span.new(
                text: span_constrained[:text],
                unconstrained: false,
                attributes: span_constrained[:attribute_list],
                source_line: SourceLineExtractor.extract(span_constrained)
              )
            end

            # Span (unconstrained)
            rule(span_unconstrained: subtree(:span_unconstrained)) do
              Model::Inline::Span.new(
                text: span_unconstrained[:text],
                unconstrained: true,
                attributes: span_unconstrained[:attribute_list],
                source_line: SourceLineExtractor.extract(span_unconstrained)
              )
            end

            # Superscript
            rule(superscript: subtree(:superscript)) do
              content = Transformer.extract_simple_inline_content(superscript)
              Model::Inline::Superscript.new(
                content:,
                source_line: SourceLineExtractor.extract(superscript)
              )
            end

            # Subscript
            rule(subscript: subtree(:subscript)) do
              content = Transformer.extract_simple_inline_content(subscript)
              Model::Inline::Subscript.new(
                content:,
                source_line: SourceLineExtractor.extract(subscript)
              )
            end

            # Highlight (simple)
            rule(highlight: simple(:text)) do
              Model::Highlight.new(
                content: text,
                source_line: SourceLineExtractor.extract(text)
              )
            end
            # Stem
            rule(stem: subtree(:stem)) do
              Coradoc::AsciiDoc::Model::Inline::Stem.new(
                type: stem[:stem_type],
                content: stem[:content],
                source_line: SourceLineExtractor.extract(stem)
              )
            end
          end
        end
      end
    end
  end
end
