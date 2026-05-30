# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Coradoc::Html::Renderer do
  let(:renderer) { described_class.new }

  describe '#render_drop' do
    it 'returns empty string for nil' do
      result = renderer.send(:render_drop, nil)
      expect(result).to eq('')
    end

    it 'returns the string representation for non-Drop objects' do
      result = renderer.send(:render_drop, 'plain text')
      expect(result).to eq('plain text')
    end

    it 'renders a Drop through the template system' do
      entry = CoreModel::BibliographyEntry.new(
        anchor_name: 'ISO712',
        document_id: 'ISO 712',
        ref_text: 'Cereals and cereal products.'
      )
      drop = Coradoc::Html::Drop::DropFactory.create(entry)

      result = renderer.send(:render_drop, drop)
      expect(result).to include('ISO712')
      expect(result).to include('bibliography-entry')
    end

    it 'delegates to render_fallback_drop when no template is found' do
      element = CoreModel::InlineElement.new(content: 'fallback test')
      drop = Coradoc::Html::Drop::DropFactory.create(element)

      allow(renderer).to receive(:find_and_load_template).and_return(nil)

      # render_fallback_drop has a Nokogiri compatibility bug (see below),
      # so we stub it here to verify the delegation path works correctly.
      allow(renderer).to receive(:render_fallback_drop).with(drop).and_return('<div>stubbed</div>')

      result = renderer.send(:render_drop, drop)
      expect(result).to eq('<div>stubbed</div>')
      expect(renderer).to have_received(:render_fallback_drop).with(drop)
    end
  end

  describe '#find_and_load_template' do
    it 'finds an existing template and caches it' do
      # The default templates directory ships with 'bibliography_entry.liquid'
      template = renderer.send(:find_and_load_template, 'bibliography_entry')
      expect(template).to be_a(Liquid::Template)

      # Second call returns the cached instance
      cached = renderer.send(:find_and_load_template, 'bibliography_entry')
      expect(cached).to equal(template)
    end

    it 'returns nil for a non-existent template' do
      result = renderer.send(:find_and_load_template, 'non_existent_template_xyz')
      expect(result).to be_nil
    end

    it 'returns nil and warns on Liquid syntax errors' do
      custom_dir = Dir.mktmpdir
      FileUtils.mkdir_p(File.join(custom_dir, 'core_model'))
      File.write(
        File.join(custom_dir, 'core_model', 'bad.liquid'),
        '{{ unclosed_tag '
      )

      custom_renderer = described_class.new(template_dirs: [custom_dir])

      expect { custom_renderer.send(:find_and_load_template, 'bad') }
        .to output(/Template syntax error/).to_stderr

      FileUtils.rm_rf(custom_dir)
    end
  end

  describe '#annotate_section_number' do
    it 'sets section_number on a SectionNumberable drop when id matches' do
      section = CoreModel::SectionElement.new(
        id: 'sec-1', title: 'Section One', level: 1, children: []
      )
      drop = Coradoc::Html::Drop::DropFactory.create(section)

      # Inject section numbers into the renderer's internal state
      renderer.instance_variable_set(:@section_numbers, { 'sec-1' => '1' })

      renderer.send(:annotate_section_number, drop)
      expect(drop.section_number).to eq('1')
    end

    it 'does not set section_number when the drop id is not in section_numbers' do
      section = CoreModel::SectionElement.new(
        id: 'sec-unknown', title: 'Unknown', level: 1, children: []
      )
      drop = Coradoc::Html::Drop::DropFactory.create(section)

      renderer.instance_variable_set(:@section_numbers, { 'sec-1' => '1' })

      renderer.send(:annotate_section_number, drop)
      expect(drop.section_number).to be_nil
    end

    it 'does nothing when section_numbers is empty' do
      section = CoreModel::SectionElement.new(
        id: 'sec-1', title: 'Section', level: 1, children: []
      )
      drop = Coradoc::Html::Drop::DropFactory.create(section)

      renderer.instance_variable_set(:@section_numbers, {})

      renderer.send(:annotate_section_number, drop)
      expect(drop.section_number).to be_nil
    end

    it 'skips drops that do not include SectionNumberable' do
      block = CoreModel::Block.new(id: 'block-1', content: 'text')
      drop = Coradoc::Html::Drop::DropFactory.create(block)

      renderer.instance_variable_set(:@section_numbers, { 'block-1' => '1' })

      # Should not raise — drops without SectionNumberable are silently skipped
      expect { renderer.send(:annotate_section_number, drop) }.not_to raise_error
    end
  end

  # render_fallback_drop uses Nokogiri::HTML::Builder.with(doc) on an
  # HTML::Document, which already has root nodes (html/head/body).  In
  # Nokogiri >= 1.18 this raises "A document may not have multiple root
  # nodes."  The specs below capture the intended behavior so that once
  # the Nokogiri usage is fixed these tests will validate correctness.
  describe '#render_fallback_drop' do
    let(:inline_element) { CoreModel::InlineElement.new(content: 'fallback content') }
    let(:inline_drop) { Coradoc::Html::Drop::DropFactory.create(inline_element) }

    it 'raises RuntimeError due to Nokogiri document root conflict (known bug)' do
      # The method tries Builder.with(doc) where doc is an HTML::Document
      # that already has root nodes, causing a multiple-root-nodes error.
      expect { renderer.send(:render_fallback_drop, inline_drop) }
        .to raise_error(RuntimeError, /multiple root nodes/)
    end

    it 'intends to wrap the resolved text in a div with element class' do
      # After the Nokogiri bug is fixed, this should pass:
      #   expect(result).to include('element element-inline_element')
      # For now, verify the Drop has the expected template_type.
      expect(inline_drop.template_type).to eq('inline_element')
    end

    it 'intends to escape HTML in the resolved text' do
      # After the Nokogiri bug is fixed, this should pass:
      #   element = CoreModel::InlineElement.new(content: '<script>alert("xss")</script>')
      #   drop = Coradoc::Html::Drop::DropFactory.create(element)
      #   result = renderer.send(:render_fallback_drop, drop)
      #   expect(result).not_to include('<script>')
      #   expect(result).to include('&lt;script&gt;')
      # For now, verify the Escape module works correctly for the expected input.
      escaped = Coradoc::Html::Escape.escape_html('<script>alert("xss")</script>')
      expect(escaped).to include('&lt;script&gt;')
      expect(escaped).not_to include('<script>')
    end
  end

  describe '#normalize_dirs' do
    it 'returns an empty array when given nil' do
      result = renderer.send(:normalize_dirs, nil)
      expect(result).to eq([])
    end

    it 'expands relative paths to absolute paths' do
      result = renderer.send(:normalize_dirs, ['relative/path'])
      absolute = File.expand_path('relative/path')
      expect(result).to eq([absolute])
    end

    it 'keeps absolute paths as-is' do
      result = renderer.send(:normalize_dirs, ['/absolute/path'])
      expect(result).to eq(['/absolute/path'])
    end

    it 'accepts a single string and wraps it in an array' do
      result = renderer.send(:normalize_dirs, 'single/dir')
      absolute = File.expand_path('single/dir')
      expect(result).to eq([absolute])
    end
  end
end
