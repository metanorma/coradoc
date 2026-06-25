# frozen_string_literal: true

require 'spec_helper'

# Pure-function specs for the four include selectors. These do not touch
# the filesystem — they exercise Tags/Lines/Indent/LevelOffset directly
# against typed IncludeOptions instances.
RSpec.describe Coradoc::IncludeSelectors do
  def opts(attrs = {})
    Coradoc::CoreModel::IncludeOptions.new(
      tags: attrs.fetch(:tags, []),
      tags_wildcard: attrs.fetch(:tags_wildcard, false),
      tags_inverted: attrs.fetch(:tags_inverted, false),
      lines_spec: attrs.fetch(:lines_spec, nil),
      leveloffset: attrs.fetch(:leveloffset, nil),
      indent: attrs.fetch(:indent, nil)
    )
  end

  describe Coradoc::IncludeSelectors::Tags do
    it 'returns text unchanged when no tags are requested' do
      expect(described_class.call("body\n", options: opts)).to eq("body\n")
    end

    it 'extracts the region between tag:: and end:: markers' do
      text = "// tag::body[]\ninside\n// end::body[]\n"
      expect(described_class.call(text, options: opts(tags: ['body']))).to eq("inside\n")
    end

    it 'supports the comment-prefixed form ## tag::name[]' do
      text = "## tag::body[]\ninside\n## end::body[]\n"
      expect(described_class.call(text, options: opts(tags: ['body']))).to eq("inside\n")
    end

    it 'extracts multiple tag regions in source order' do
      text = %(// tag::a[]\nA\n// end::a[]\nmiddle\n// tag::b[]\nB\n// end::b[]\n)
      result = described_class.call(text, options: opts(tags: %w[a b]))
      expect(result).to eq("A\nB\n")
    end

    it 'returns empty for an unknown tag name' do
      text = "// tag::body[]\ninside\n// end::body[]\n"
      expect(described_class.call(text, options: opts(tags: ['nope']))).to eq('')
    end

    it 'wildcard (*) selects all tagged regions' do
      text = %(outside\n// tag::a[]\nA\n// end::a[]\nmiddle\n// tag::b[]\nB\n// end::b[]\n)
      result = described_class.call(text, options: opts(tags_wildcard: true))
      expect(result).to eq("A\nB\n")
    end

    it 'inverted (**) selects everything except tagged regions and markers' do
      text = %(outside\n// tag::a[]\nA\n// end::a[]\nafter\n)
      result = described_class.call(text, options: opts(tags_inverted: true))
      expect(result).to include('outside', 'after')
      expect(result).not_to include('tag::', 'end::', 'A')
    end

    it 'drops the tag marker lines from the output' do
      text = "// tag::body[]\ninside\n// end::body[]\n"
      result = described_class.call(text, options: opts(tags: ['body']))
      expect(result).not_to include('tag::')
      expect(result).not_to include('end::')
    end
  end

  describe Coradoc::IncludeSelectors::Lines do
    it 'returns text unchanged when no line spec is set' do
      expect(described_class.call("body\n", options: opts)).to eq("body\n")
    end

    it 'selects a single line by 1-indexed number' do
      expect(described_class.call("a\nb\nc\n", options: opts(lines_spec: '2'))).to eq("b\n")
    end

    it 'selects an inclusive range' do
      expect(described_class.call("a\nb\nc\nd\n", options: opts(lines_spec: '2..3')))
        .to eq("b\nc\n")
    end

    it 'selects discontinuous ranges separated by semicolons' do
      expect(described_class.call("a\nb\nc\nd\ne\n", options: opts(lines_spec: '1;3..4')))
        .to eq("a\nc\nd\n")
    end

    it 'clamps out-of-bounds ranges to the available content' do
      expect(described_class.call("a\nb\n", options: opts(lines_spec: '1..99')))
        .to eq("a\nb\n")
    end
  end

  describe Coradoc::IncludeSelectors::Indent do
    it 'returns text unchanged when no indent is set' do
      expect(described_class.call("  body\n", options: opts)).to eq("  body\n")
    end

    it 'strips all leading whitespace when indent=0' do
      expect(described_class.call("  body\n\ttabs\n", options: opts(indent: 0)))
        .to eq("body\ntabs\n")
    end
  end

  describe Coradoc::IncludeSelectors::LevelOffset do
    def doc_with_section(level:)
      Coradoc::CoreModel::DocumentElement.new(
        children: [Coradoc::CoreModel::SectionElement.new(level: level, title: 'S')]
      )
    end

    it 'returns the document unchanged when no offset is set' do
      doc = doc_with_section(level: 2)
      result = described_class.call(doc, options: opts)
      expect(result.children.first.level).to eq(2)
    end

    it 'shifts levels by a relative offset (+N)' do
      offset = Coradoc::CoreModel::IncludeLevelOffset.parse('+2')
      doc = doc_with_section(level: 1)
      result = described_class.call(doc, options: opts(leveloffset: offset))
      expect(result.children.first.level).to eq(3)
    end

    it 'shifts levels by a negative offset' do
      offset = Coradoc::CoreModel::IncludeLevelOffset.parse('-1')
      doc = doc_with_section(level: 3)
      result = described_class.call(doc, options: opts(leveloffset: offset))
      expect(result.children.first.level).to eq(2)
    end
  end
end
