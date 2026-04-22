# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Module containing inline element transformation rules
      module InlineRules
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
            rule(href: simple(:href)) do
              Model::Inline::CrossReference.new(href: href.to_s)
            end

            rule(
              href: simple(:href),
              name: simple(:name)
            ) do
              Model::Inline::CrossReference.new(href: href.to_s, args: [name.to_s])
            end

            rule(cross_reference: sequence(:xref)) do
              args = xref.size > 1 ? xref[1..] : []
              Model::Inline::CrossReference.new(href: xref[0], args:)
            end

            # Inline image
            rule(inline_image: subtree(:inline_image)) do
              Model::Image::InlineImage.new(
                title: inline_image[:text],
                src: inline_image[:path],
                attributes: inline_image[:attribute_list]
              )
            end

            # Attribute reference
            rule(attribute_reference: simple(:name)) do
              Model::Inline::AttributeReference.new(name:)
            end

            # Term
            rule(
              term_type: simple(:term_type),
              term: simple(:term)
            ) do
              Coradoc::AsciiDoc::Model::Term.new(term:, type: term_type, lang: :en)
            end

            # Footnote
            rule(footnote: simple(:footnote)) do
              text_str = footnote.to_s
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(text: text_str)
            end

            rule(footnote: simple(:footnote), id: simple(:id)) do
              text_str = footnote.to_s
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(text: text_str, id: id.to_s)
            end

            # Footnote with empty content (reference to named footnote)
            rule(footnote: sequence(:footnote), id: simple(:id)) do
              text_str = footnote.map(&:to_s).join
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(text: text_str, id: id.to_s)
            end

            # Footnote with empty content and no id
            rule(footnote: sequence(:footnote)) do
              text_str = footnote.map(&:to_s).join
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(text: text_str)
            end

            # Href arg
            rule(href_arg: simple(:href_arg)) do
              href_arg.to_s
            end

            # Bold (constrained)
            rule(bold_constrained: subtree(:bold)) do
              content = Transformer.extract_inline_content(bold)
              Model::Inline::Bold.new(content: content, unconstrained: false)
            end

            # Bold (unconstrained)
            rule(bold_unconstrained: subtree(:bold)) do
              content = Transformer.extract_inline_content(bold)
              Model::Inline::Bold.new(content: content, unconstrained: true)
            end

            # Italic (constrained)
            rule(italic_constrained: subtree(:italic)) do
              content = Transformer.extract_inline_content(italic)
              Model::Inline::Italic.new(content: content, unconstrained: false)
            end

            # Italic (unconstrained)
            rule(italic_unconstrained: subtree(:italic)) do
              content = Transformer.extract_inline_content(italic)
              Model::Inline::Italic.new(content: content, unconstrained: true)
            end

            # Highlight (constrained)
            rule(highlight_constrained: subtree(:highlight)) do
              content = Transformer.extract_inline_content(highlight)
              Model::Inline::Highlight.new(content: content, unconstrained: false)
            end

            # Highlight (unconstrained)
            rule(highlight_unconstrained: subtree(:highlight)) do
              content = Transformer.extract_inline_content(highlight)
              Model::Inline::Highlight.new(content: content, unconstrained: true)
            end

            # Monospace (constrained)
            rule(monospace_constrained: subtree(:monospace)) do
              content = Transformer.extract_inline_content(monospace)
              Model::Inline::Monospace.new(content: content, unconstrained: false)
            end

            # Monospace (unconstrained)
            rule(monospace_unconstrained: subtree(:monospace)) do
              content = Transformer.extract_inline_content(monospace)
              Model::Inline::Monospace.new(content: content, unconstrained: true)
            end

            # Superscript
            rule(superscript: subtree(:superscript)) do
              content = Transformer.extract_simple_inline_content(superscript)
              Model::Inline::Superscript.new(content:)
            end

            # Subscript
            rule(subscript: subtree(:subscript)) do
              content = Transformer.extract_simple_inline_content(subscript)
              Model::Inline::Subscript.new(content:)
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

            # Highlight (simple)
            rule(highlight: simple(:text)) do
              Model::Highlight.new(content: text)
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
