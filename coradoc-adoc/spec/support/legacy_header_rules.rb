# frozen_string_literal: true

require_relative 'legacy_list_rules'

# Frozen copy of the hand-written header/author/revision/paragraph rules that the
# M3 bindings retired (header_rules.rb, and the paragraph rule of
# text_rules.rb, at ecf32a2). The bound-vs-unbound differential applies
# them to a Transformer subclass as the reference the bindings must match.
module LegacyHeaderRules
  def self.apply(transformer_class)
    transformer_class.class_eval do
      rule(header: subtree(:header)) do
        title = header[:title]
        author = header[:author]
        revision = header[:revision]

        id = header[:id]
        id = title.id if title.is_a?(Coradoc::AsciiDoc::Model::Title) && title.id && !id
        id = id.to_s unless id.nil?
        id = nil if id && id.empty?

        Coradoc::AsciiDoc::Model::Header.new(id:, title:, author:, revision:)
      end

      rule(header: simple(:header)) do
        header
      end

      rule(paragraph: subtree(:paragraph)) do
        Coradoc::AsciiDoc::Model::Paragraph.new(
          content: Coradoc::AsciiDoc::Transformer.lines_to_text_elements(paragraph[:lines]),
          id: paragraph[:id],
          attributes: paragraph[:attribute_list],
          title: paragraph[:title]
        )
      end

      rule(first_name: simple(:first_name), last_name: simple(:last_name), email: simple(:email)) do
        Coradoc::AsciiDoc::Model::Author.new(first_name:, last_name:, email:, middle_name: nil)
      end

      rule(number: simple(:number), date: simple(:date), remark: simple(:remark)) do
        Coradoc::AsciiDoc::Model::Revision.new(number:, date:, remark:)
      end
    end
  end

  # A Transformer with every retired rule set and no bindings.
  def self.transformer
    @transformer ||= Class.new(Coradoc::AsciiDoc::Transformer).tap do |klass|
      apply(klass)
      LegacyListRules.apply(klass)
    end
  end
end
