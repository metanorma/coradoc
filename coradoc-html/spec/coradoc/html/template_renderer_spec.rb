# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Coradoc::Html::TemplateLocator do
  let(:default_dir) do
    Pathname.new(File.join(
                   File.dirname(__FILE__),
                   '../../../../lib/coradoc/html/templates/core_model'
                 ))
  end

  describe '#initialize' do
    it 'accepts user directories' do
      locator = described_class.new(user_dirs: ['/tmp/templates'])
      expect(locator.user_dirs.map(&:to_s)).to include('/tmp/templates')
    end

    it 'uses default template directory' do
      locator = described_class.new(user_dirs: [])
      expect(locator.default_dir.to_s).to include('templates/core_model')
    end
  end

  describe '#find' do
    context 'with default templates only' do
      let(:locator) { described_class.new(user_dirs: [], default_dir: default_dir) }

      it 'finds bibliography template' do
        skip 'Default templates not yet created' unless default_dir.join('bibliography.liquid').exist?
        result = locator.find('bibliography')
        expect(result).to be_a(Pathname)
        expect(result.to_s).to end_with('bibliography.liquid')
      end

      it 'returns nil for non-existent templates' do
        result = locator.find('non_existent_template_xyz')
        expect(result).to be_nil
      end
    end

    context 'with user override directories' do
      let(:user_dir) { Dir.mktmpdir }
      let(:locator) { described_class.new(user_dirs: [user_dir], default_dir: default_dir) }

      before do
        FileUtils.mkdir_p(File.join(user_dir, 'core_model'))
      end

      after do
        FileUtils.rm_rf(user_dir)
      end

      it 'checks user directories first' do
        # Create custom template
        File.write(File.join(user_dir, 'core_model', 'test.liquid'), '<p>TEST</p>')

        result = locator.find('test')
        expect(result.to_s).to include(user_dir)
      end
    end
  end
end

RSpec.describe Coradoc::Html::Renderer do
  describe '#initialize' do
    it 'accepts template directories' do
      renderer = described_class.new(template_dirs: ['/custom/templates'])
      expect(renderer.template_dirs).to eq(['/custom/templates'])
    end

    it 'accepts options' do
      renderer = described_class.new(options: { strict: true })
      expect(renderer.options[:strict]).to be true
    end
  end

  describe '#render' do
    let(:renderer) { described_class.new }

    context 'with primitives' do
      it 'escapes HTML in strings' do
        result = renderer.render("<script>alert('xss')</script>")
        expect(result).to include('&lt;script&gt;')
      end

      it 'renders arrays by joining elements' do
        result = renderer.render(%w[hello world])
        expect(result).to eq("hello\nworld")
      end

      it 'returns empty string for nil' do
        expect(renderer.render(nil)).to eq('')
      end

      it 'converts numbers to strings' do
        expect(renderer.render(42)).to eq('42')
      end

      it 'converts booleans to strings' do
        expect(renderer.render(true)).to eq('true')
        expect(renderer.render(false)).to eq('false')
      end
    end

    context 'with CoreModel::BibliographyEntry' do
      let(:entry) do
        Coradoc::CoreModel::BibliographyEntry.new(
          anchor_name: 'ISO712',
          document_id: 'ISO 712',
          ref_text: 'Cereals and cereal products.'
        )
      end

      it 'renders entry using template' do
        result = renderer.render(entry)
        # Should use the bibliography_entry.liquid template
        expect(result).to include('ISO712')
      end

      it 'includes bibliography-entry class' do
        result = renderer.render(entry)
        expect(result).to include('bibliography-entry')
      end
    end

    context 'with CoreModel::Bibliography' do
      let(:entries) do
        [
          Coradoc::CoreModel::BibliographyEntry.new(
            anchor_name: 'ISO712',
            document_id: 'ISO 712',
            ref_text: 'Cereals.'
          ),
          Coradoc::CoreModel::BibliographyEntry.new(
            anchor_name: 'ISO6646',
            document_id: 'ISO 6646',
            ref_text: 'Rice.'
          )
        ]
      end

      let(:bibliography) do
        Coradoc::CoreModel::Bibliography.new(
          id: 'norm-refs',
          title: 'Normative References',
          level: 1,
          entries: entries
        )
      end

      it 'renders bibliography section using template' do
        result = renderer.render(bibliography)
        expect(result).to include('norm-refs')
        expect(result).to include('bibliography')
      end

      it 'renders all entries' do
        result = renderer.render(bibliography)
        expect(result).to include('ISO712')
        expect(result).to include('ISO6646')
      end
    end
  end

  describe '.register_type' do
    after do
      described_class.instance_variable_get(:@custom_type_map)&.delete('TestCustomClass')
    end

    it 'allows registering custom type mappings' do
      described_class.register_type('TestCustomClass', 'test_custom')
      expect(described_class.custom_type_map['TestCustomClass']).to eq('test_custom')
    end
  end

  describe 'template customization' do
    let(:custom_dir) { Dir.mktmpdir }
    let(:custom_renderer) { described_class.new(template_dirs: [custom_dir]) }

    before do
      FileUtils.mkdir_p(File.join(custom_dir, 'core_model'))
    end

    after do
      FileUtils.rm_rf(custom_dir)
    end

    it 'uses custom templates when provided' do
      custom_template = <<~LIQUID
        <p id="{{ anchor_name }}" class="custom-entry">
          CUSTOM: {{ document_id }}
        </p>
      LIQUID

      File.write(File.join(custom_dir, 'core_model', 'bibliography_entry.liquid'), custom_template)

      entry = Coradoc::CoreModel::BibliographyEntry.new(
        anchor_name: 'TEST',
        document_id: 'TEST 123'
      )

      result = custom_renderer.render(entry)
      expect(result).to include('custom-entry')
      expect(result).to include('CUSTOM:')
    end
  end
end
