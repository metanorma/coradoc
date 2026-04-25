# frozen_string_literal: true

require_relative '../../../../spec_helper'

# Shared helpers for building minimal OOXML test fixtures
module RuleSpecHelper
  def build_context(registry: nil)
    Coradoc::Docx::Transform::Context.new(registry: registry)
  end

  def build_registry_with(*rules)
    registry = Coradoc::Docx::Transform::RuleRegistry.new
    rules.each { |r| registry.register(r) }
    registry
  end

  def build_text_run(text)
    run = Uniword::Wordprocessingml::Run.new
    run.text = Uniword::Wordprocessingml::Text.new(content: text)
    run
  end

  def build_formatted_run(text, bold: false, italic: false, underline: false, strike: false)
    run = Uniword::Wordprocessingml::Run.new
    run.text = Uniword::Wordprocessingml::Text.new(content: text)
    props = Uniword::Wordprocessingml::RunProperties.new
    props.bold = Uniword::Properties::Bold.new if bold
    props.italic = Uniword::Properties::Italic.new if italic
    props.underline = Uniword::Properties::Underline.new if underline
    props.strike = Uniword::Properties::Strike.new if strike
    run.properties = props
    run
  end

  def build_bookmark_start(id:, name:)
    bm = Uniword::Wordprocessingml::BookmarkStart.new
    bm.id = id
    bm.name = name
    bm
  end

  def build_break(type: nil)
    brk = Uniword::Wordprocessingml::Break.new
    brk.type = type
    brk
  end

  def build_hyperlink(runs:, id: nil, anchor: nil)
    hl = Uniword::Wordprocessingml::Hyperlink.new
    hl.runs = Array(runs)
    hl.id = id
    hl.anchor = anchor
    hl
  end
end

RSpec.configure do |config|
  config.include RuleSpecHelper
end

RSpec.describe Coradoc::Docx::Transform::Rules::RunRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'matches Run elements' do
      expect(rule.matches?(Uniword::Wordprocessingml::Run.new)).to be true
    end

    it 'does not match other elements' do
      expect(rule.matches?(Object.new)).to be false
    end
  end

  describe '#apply' do
    let(:context) { build_context }

    it 'returns plain text for unformatted runs' do
      run = build_text_run('hello')

      expect(rule.apply(run, context)).to eq('hello')
    end

    it 'returns InlineElement for bold runs' do
      run = build_formatted_run('bold', bold: true)

      result = rule.apply(run, context)
      expect(result).to be_a(Coradoc::CoreModel::InlineElement)
      expect(result.format_type).to eq('bold')
      expect(result.content).to eq('bold')
    end

    it 'returns InlineElement for italic runs' do
      run = build_formatted_run('italic', italic: true)

      result = rule.apply(run, context)
      expect(result).to be_a(Coradoc::CoreModel::InlineElement)
      expect(result.format_type).to eq('italic')
    end

    it 'returns InlineElement for underline runs' do
      run = build_formatted_run('under', underline: true)

      result = rule.apply(run, context)
      expect(result.format_type).to eq('underline')
    end

    it 'returns InlineElement for strikethrough runs' do
      run = build_formatted_run('struck', strike: true)

      result = rule.apply(run, context)
      expect(result.format_type).to eq('strikethrough')
    end

    it 'returns empty string for run with no text' do
      run = Uniword::Wordprocessingml::Run.new

      expect(rule.apply(run, context)).to eq('')
    end
  end
end

RSpec.describe Coradoc::Docx::Transform::Rules::TextRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'matches Text elements' do
      expect(rule.matches?(Uniword::Wordprocessingml::Text.new)).to be true
    end
  end

  describe '#apply' do
    it 'returns the text content as string' do
      text = Uniword::Wordprocessingml::Text.new(content: 'Hello World')
      context = build_context

      expect(rule.apply(text, context)).to eq('Hello World')
    end
  end
end

RSpec.describe Coradoc::Docx::Transform::Rules::ParagraphRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'matches Paragraph elements' do
      expect(rule.matches?(Uniword::Wordprocessingml::Paragraph.new)).to be true
    end
  end

  describe '#apply' do
    let(:context) { build_context(registry: build_registry_with(described_class.new, Coradoc::Docx::Transform::Rules::RunRule.new, Coradoc::Docx::Transform::Rules::TextRule.new)) }

    it 'produces a Block paragraph with text content' do
      para = build_paragraph('Hello')

      result = rule.apply(para, context)
      expect(result).to be_a(Coradoc::CoreModel::Block)
      expect(result.element_type).to eq('paragraph')
      expect(result.content).to eq('Hello')
    end

    it 'preserves inline formatting as children' do
      para = build_paragraph(build_formatted_run('bold', bold: true))

      result = rule.apply(para, context)
      expect(result.children.length).to eq(1)
      expect(result.children.first.format_type).to eq('bold')
    end

    it 'extracts bookmark ID from paragraph' do
      para = build_paragraph('text')
      bm = build_bookmark_start(id: 'bm1', name: 'mybookmark')
      allow(para).to receive(:bookmark_starts).and_return([bm])

      result = rule.apply(para, context)
      expect(result.id).to eq('bm1')
    end
  end
end

RSpec.describe Coradoc::Docx::Transform::Rules::TableRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'matches Table elements' do
      expect(rule.matches?(Uniword::Wordprocessingml::Table.new)).to be true
    end
  end

  describe '#apply' do
    let(:context) { build_context(registry: build_registry_with(described_class.new, Coradoc::Docx::Transform::Rules::ParagraphRule.new, Coradoc::Docx::Transform::Rules::RunRule.new, Coradoc::Docx::Transform::Rules::TextRule.new)) }

    it 'produces a CoreModel::Table with rows and cells' do
      table = build_table([%w[A B], %w[C D]])

      result = rule.apply(table, context)
      expect(result).to be_a(Coradoc::CoreModel::Table)
      expect(result.rows.length).to eq(2)
      expect(result.rows[0].cells.length).to eq(2)
      expect(result.rows[0].cells[0].content).to eq('A')
      expect(result.rows[1].cells[1].content).to eq('D')
    end
  end
end

RSpec.describe Coradoc::Docx::Transform::Rules::ListItemRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'never auto-matches (orchestrator dispatches directly)' do
      expect(rule.matches?(Uniword::Wordprocessingml::Paragraph.new)).to be false
    end
  end

  describe '#apply' do
    let(:context) { build_context(registry: build_registry_with(Coradoc::Docx::Transform::Rules::RunRule.new, Coradoc::Docx::Transform::Rules::TextRule.new)) }

    it 'produces a ListItem with content' do
      para = build_list_paragraph('Item 1', num_id: 1)

      result = rule.apply(para, context)
      expect(result).to be_a(Coradoc::CoreModel::ListItem)
      expect(result.content).to eq('Item 1')
    end

    it 'uses * marker for level 0' do
      para = build_list_paragraph('Item', num_id: 1, ilvl: 0)

      result = rule.apply(para, context)
      expect(result.marker).to eq('*')
    end
  end
end

RSpec.describe Coradoc::Docx::Transform::Rules::HeadingRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'never auto-matches (orchestrator dispatches directly)' do
      expect(rule.matches?(Uniword::Wordprocessingml::Paragraph.new)).to be false
    end
  end

  describe '#apply' do
    let(:context) { build_context(registry: build_registry_with(Coradoc::Docx::Transform::Rules::RunRule.new, Coradoc::Docx::Transform::Rules::TextRule.new)) }

    it 'produces a StructuralElement section with title and level' do
      para = build_heading('My Title', level: 2)
      allow(context.style_resolver).to receive(:heading_level).and_return(2)

      result = rule.apply(para, context)
      expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
      expect(result.element_type).to eq('section')
      expect(result.title).to eq('My Title')
      expect(result.level).to eq(2)
    end

    it 'extracts bookmark ID as section id' do
      para = build_heading('Section', level: 1)
      allow(context.style_resolver).to receive(:heading_level).and_return(1)
      bm = build_bookmark_start(id: 'sec1', name: '_section_1')
      allow(para).to receive(:bookmark_starts).and_return([bm])

      result = rule.apply(para, context)
      expect(result.id).to eq('sec1')
    end
  end
end

RSpec.describe Coradoc::Docx::Transform::Rules::BookmarkRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'matches BookmarkStart elements' do
      expect(rule.matches?(Uniword::Wordprocessingml::BookmarkStart.new)).to be true
    end

    it 'matches BookmarkEnd elements' do
      expect(rule.matches?(Uniword::Wordprocessingml::BookmarkEnd.new)).to be true
    end
  end

  describe '#apply' do
    let(:context) { build_context }

    it 'returns metadata hash for BookmarkStart' do
      bm = build_bookmark_start(id: '42', name: 'mybookmark')

      result = rule.apply(bm, context)
      expect(result).to eq({ id: '42', name: 'mybookmark' })
    end

    it 'returns nil for BookmarkEnd' do
      bm_end = Uniword::Wordprocessingml::BookmarkEnd.new

      result = rule.apply(bm_end, context)
      expect(result).to be_nil
    end
  end
end

RSpec.describe Coradoc::Docx::Transform::Rules::BreakRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'matches Break elements' do
      expect(rule.matches?(Uniword::Wordprocessingml::Break.new)).to be true
    end
  end

  describe '#apply' do
    let(:context) { build_context }

    it 'produces page_break Block for page break' do
      brk = build_break(type: 'page')

      result = rule.apply(brk, context)
      expect(result).to be_a(Coradoc::CoreModel::Block)
      expect(result.element_type).to eq('page_break')
    end

    it 'produces hard_line_break InlineElement for line break' do
      brk = build_break(type: nil)

      result = rule.apply(brk, context)
      expect(result).to be_a(Coradoc::CoreModel::InlineElement)
      expect(result.format_type).to eq('hard_line_break')
    end
  end
end

RSpec.describe Coradoc::Docx::Transform::Rules::FootnoteRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'matches FootnoteReference elements' do
      expect(rule.matches?(Uniword::Wordprocessingml::FootnoteReference.new)).to be true
    end
  end

  describe '#apply' do
    let(:context) { build_context }

    it 'produces a FootnoteReference with id' do
      ref = Uniword::Wordprocessingml::FootnoteReference.new
      ref.id = '3'

      result = rule.apply(ref, context)
      expect(result).to be_a(Coradoc::CoreModel::FootnoteReference)
      expect(result.id).to eq('3')
    end
  end
end

RSpec.describe Coradoc::Docx::Transform::Rules::HyperlinkRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'matches Hyperlink elements' do
      expect(rule.matches?(Uniword::Wordprocessingml::Hyperlink.new)).to be true
    end
  end

  describe '#apply' do
    let(:run_rule) { Coradoc::Docx::Transform::Rules::RunRule.new }
    let(:context) { build_context(registry: build_registry_with(run_rule, Coradoc::Docx::Transform::Rules::TextRule.new)) }

    it 'produces InlineElement link with external URL' do
      hl = build_hyperlink(
        runs: [build_text_run('Click here')],
        id: 'https://example.com'
      )

      result = rule.apply(hl, context)
      expect(result).to be_a(Coradoc::CoreModel::InlineElement)
      expect(result.format_type).to eq('link')
      expect(result.target).to eq('https://example.com')
      expect(result.content).to eq('Click here')
    end

    it 'produces InlineElement link with anchor for internal links' do
      hl = build_hyperlink(
        runs: [build_text_run('Go to section')],
        anchor: 'section_1'
      )

      result = rule.apply(hl, context)
      expect(result.target).to eq('#section_1')
    end
  end
end

RSpec.describe Coradoc::Docx::Transform::Rules::ProofErrorRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'does not match when ProofError class is not defined' do
      expect(rule.matches?(Object.new)).to be_falsey
    end
  end

  describe '#apply' do
    it 'returns nil (silently ignored)' do
      err = Object.new
      context = build_context

      expect(rule.apply(err, context)).to be_nil
    end
  end
end

RSpec.describe Coradoc::Docx::Transform::Rules::SimpleFieldRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'matches SimpleField elements' do
      expect(rule.matches?(Uniword::Wordprocessingml::SimpleField.new)).to be true
    end
  end

  describe '#apply' do
    let(:context) { build_context(registry: build_registry_with(Coradoc::Docx::Transform::Rules::RunRule.new, Coradoc::Docx::Transform::Rules::TextRule.new)) }

    it 'returns nil for PAGE field (print layout)' do
      field = Uniword::Wordprocessingml::SimpleField.new
      field.instr = 'PAGE'
      field.runs = [build_text_run('1')]

      expect(rule.apply(field, context)).to be_nil
    end

    it 'returns text for TITLE field' do
      field = Uniword::Wordprocessingml::SimpleField.new
      field.instr = 'TITLE'
      field.runs = [build_text_run('My Doc')]

      expect(rule.apply(field, context)).to eq('My Doc')
    end
  end
end

RSpec.describe Coradoc::Docx::Transform::Rules::StructuredDocumentTagRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'matches StructuredDocumentTag elements' do
      expect(rule.matches?(Uniword::Wordprocessingml::StructuredDocumentTag.new)).to be true
    end
  end

  describe '#apply' do
    let(:context) { build_context(registry: build_registry_with(Coradoc::Docx::Transform::Rules::ParagraphRule.new, Coradoc::Docx::Transform::Rules::RunRule.new, Coradoc::Docx::Transform::Rules::TextRule.new)) }

    it 'unwraps SDT content and delegates to paragraph rules' do
      sdt = Uniword::Wordprocessingml::StructuredDocumentTag.new
      content = instance_double('content')
      allow(sdt).to receive(:content).and_return(content)
      allow(content).to receive(:paragraphs).and_return([build_paragraph('SDT content')])
      allow(content).to receive(:tables).and_return([])

      result = rule.apply(sdt, context)
      expect(result).to be_a(Coradoc::CoreModel::Block)
      expect(result.content).to eq('SDT content')
    end

    it 'returns nil when SDT has no content' do
      sdt = Uniword::Wordprocessingml::StructuredDocumentTag.new
      allow(sdt).to receive(:content).and_return(nil)

      expect(rule.apply(sdt, context)).to be_nil
    end
  end
end

RSpec.describe Coradoc::Docx::Transform::Rules::ImageRule do
  subject(:rule) { described_class.new }

  describe '#matches?' do
    it 'matches Drawing elements' do
      expect(rule.matches?(Uniword::Wordprocessingml::Drawing.new)).to be true
    end

    it 'matches Picture elements' do
      expect(rule.matches?(Uniword::Wordprocessingml::Picture.new)).to be true
    end
  end

  describe '#apply' do
    let(:context) { build_context }

    it 'produces an Image with nil src for drawing without embed' do
      drawing = Uniword::Wordprocessingml::Drawing.new
      allow(drawing).to receive(:inline).and_return(nil)
      allow(drawing).to receive(:anchor).and_return(nil)

      result = rule.apply(drawing, context)
      expect(result).to be_a(Coradoc::CoreModel::Image)
      expect(result.src).to be_nil
    end
  end
end
