# frozen_string_literal: true

module Coradoc
  module Markdown
    module Transform
      module InlineTransformer
        class << self
          def transform_inline(element)
            case element.resolve_format_type
            when 'bold'
              Coradoc::Markdown::Strong.new(text: element.content.to_s)
            when 'italic'
              Coradoc::Markdown::Emphasis.new(text: element.content.to_s)
            when 'monospace'
              Coradoc::Markdown::Code.new(text: element.content.to_s)
            when 'link'
              Coradoc::Markdown::Link.new(
                text: element.content.to_s,
                url: element.target.to_s
              )
            when 'footnote'
              Coradoc::Markdown::FootnoteReference.new(id: element.target.to_s)
            when 'stem'
              Coradoc::Markdown::Math.inline(element.content.to_s)
            when 'highlight'
              Coradoc::Markdown::Highlight.new(text: element.content.to_s)
            when 'strikethrough'
              Coradoc::Markdown::Strikethrough.new(text: element.content.to_s)
            when 'subscript'
              Coradoc::Markdown::Subscript.new(text: element.content.to_s)
            when 'superscript'
              Coradoc::Markdown::Superscript.new(text: element.content.to_s)
            when 'underline'
              Coradoc::Markdown::Underline.new(text: element.content.to_s)
            when 'xref'
              Coradoc::Markdown::CrossReference.new(
                text: element.content.to_s,
                target: element.target.to_s
              )
            when 'raw_inline'
              element.content.to_s
            else
              element.content.to_s
            end
          end

          def transform_footnote(fn)
            Coradoc::Markdown::Footnote.new(
              id: fn.id.to_s,
              content: fn.content.to_s,
              backlink: fn.backlink
            )
          end

          def transform_footnote_reference(ref)
            Coradoc::Markdown::FootnoteReference.new(id: ref.id.to_s)
          end

          def transform_abbreviation(abbr)
            Coradoc::Markdown::Abbreviation.new(
              term: abbr.term.to_s,
              definition: abbr.definition.to_s
            )
          end
        end

        FromCoreModel.register(CoreModel::InlineElement, method(:transform_inline))
        FromCoreModel.register(CoreModel::Footnote, method(:transform_footnote))
        FromCoreModel.register(CoreModel::FootnoteReference, method(:transform_footnote_reference))
        FromCoreModel.register(CoreModel::Abbreviation, method(:transform_abbreviation))
        FromCoreModel.register(CoreModel::TextContent, lambda(&:text))
        FromCoreModel.register(CoreModel::Term, ->(m) { Coradoc::Markdown::Strong.new(text: m.text.to_s) })
      end
    end
  end
end
