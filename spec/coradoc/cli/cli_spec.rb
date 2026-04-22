# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/cli'
require 'fileutils'
require 'tmpdir'

RSpec.describe Coradoc::CLI do
  let(:cli) { described_class.new }

  before do
    # Ensure format gems are loaded
    require 'coradoc/html'
    require 'coradoc/markdown'
  end

  describe '#formats' do
    it 'lists supported formats' do
      output = capture_stdout { cli.formats }

      expect(output).to include('Supported formats')
      expect(output).to include('html')
      expect(output).to include('markdown')
    end
  end

  describe '#version' do
    it 'displays the version' do
      output = capture_stdout { cli.version }

      expect(output).to include('Coradoc')
      expect(output).to include(Coradoc::VERSION)
    end
  end

  describe '#convert' do
    let(:temp_dir) { Dir.mktmpdir('coradoc_cli_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    context 'with Markdown to HTML conversion' do
      let(:input_file) { File.join(temp_dir, 'input.md') }
      let(:output_file) { File.join(temp_dir, 'output.html') }
      let(:markdown_content) { "# Title\n\nParagraph content" }

      before do
        File.write(input_file, markdown_content)
      end

      it 'converts Markdown to HTML' do
        capture_stdout do
          cli.options = { to: 'html', output: output_file, verbose: false }
          cli.convert(input_file)
        end

        expect(File.exist?(output_file)).to be true
        html_content = File.read(output_file)
        expect(html_content).to include('<!DOCTYPE html>')
      end

      it 'outputs to stdout when no output file specified' do
        output = capture_stdout do
          cli.options = { to: 'html', verbose: false }
          cli.convert(input_file)
        end

        expect(output).to include('<!DOCTYPE html>')
      end
    end

    context 'with auto-detection' do
      let(:input_file) { File.join(temp_dir, 'document.md') }
      let(:markdown_content) { "# Title\n\nContent" }

      before do
        File.write(input_file, markdown_content)
      end

      it 'auto-detects source format from extension' do
        output = capture_stdout do
          cli.options = { to: 'html', verbose: false }
          cli.convert(input_file)
        end

        expect(output).to include('<!DOCTYPE html>')
      end
    end

    context 'with invalid input' do
      it 'exits with error for non-existent file' do
        expect do
          cli.options = { to: 'html', verbose: false }
          cli.convert('/nonexistent/file.md')
        end.to raise_error(SystemExit)
      end
    end
  end

  describe '#validate' do
    let(:temp_dir) { Dir.mktmpdir('coradoc_cli_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    context 'with valid Markdown document' do
      let(:input_file) { File.join(temp_dir, 'valid.md') }
      let(:markdown_content) { "# Title\n\nValid paragraph content" }

      before do
        File.write(input_file, markdown_content)
      end

      it 'runs the validate command on a parseable document' do
        expect do
          capture_stdout do
            cli.options = { format: nil, strict: false, verbose: false }
            cli.validate(input_file)
          end
        end.not_to raise_error
      end
    end

    context 'with non-existent file' do
      it 'exits with error' do
        expect do
          cli.options = { format: nil, strict: false, verbose: false }
          cli.validate('/nonexistent/file.md')
        end.to raise_error(SystemExit)
      end
    end
  end

  describe '#query' do
    let(:temp_dir) { Dir.mktmpdir('coradoc_cli_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    context 'with Markdown document' do
      let(:input_file) { File.join(temp_dir, 'query.md') }
      let(:markdown_content) { "# Main Title\n\n## Section 1\n\nParagraph 1\n\n## Section 2\n\nParagraph 2" }

      before do
        File.write(input_file, markdown_content)
      end

      it 'queries for sections' do
        output = capture_stdout do
          cli.options = { format: nil, output: 'text', verbose: false }
          cli.query(input_file, 'section')
        end

        expect(output).to include('Found')
        expect(output).to include('element')
      end

      it 'outputs in JSON format' do
        output = capture_stdout do
          cli.options = { format: nil, output: 'json', verbose: false }
          cli.query(input_file, 'paragraph')
        end

        expect(output).not_to be_empty
      end
    end

    context 'with non-existent file' do
      it 'exits with error' do
        expect do
          cli.options = { format: nil, output: 'text', verbose: false }
          cli.query('/nonexistent/file.md', 'section')
        end.to raise_error(SystemExit)
      end
    end
  end

  describe '#info' do
    let(:temp_dir) { Dir.mktmpdir('coradoc_cli_spec') }

    after do
      FileUtils.remove_entry(temp_dir) if File.directory?(temp_dir)
    end

    context 'with Markdown document' do
      let(:input_file) { File.join(temp_dir, 'info.md') }
      let(:markdown_content) { "# Document Title\n\nFirst paragraph.\n\nSecond paragraph." }

      before do
        File.write(input_file, markdown_content)
      end

      it 'displays document information' do
        output = capture_stdout do
          cli.options = { format: nil, verbose: false }
          cli.info(input_file)
        end

        expect(output).to include('Document Information')
        expect(output).to include('Format: markdown')
        expect(output).to include('File size:')
        expect(output).to include('Line count:')
      end
    end

    context 'with non-existent file' do
      it 'exits with error' do
        expect do
          cli.options = { format: nil, verbose: false }
          cli.info('/nonexistent/file.md')
        end.to raise_error(SystemExit)
      end
    end
  end

  describe '.exit_on_failure?' do
    it 'returns true' do
      expect(described_class.exit_on_failure?).to be true
    end
  end

  describe 'FORMAT_ALIASES' do
    it 'maps common aliases to format names' do
      expect(described_class::FORMAT_ALIASES['adoc']).to eq(:asciidoc)
      expect(described_class::FORMAT_ALIASES['md']).to eq(:markdown)
      expect(described_class::FORMAT_ALIASES['html']).to eq(:html)
      expect(described_class::FORMAT_ALIASES['docx']).to eq(:docx)
    end
  end

  describe 'EXTENSION_FORMATS' do
    it 'maps file extensions to formats' do
      expect(described_class::EXTENSION_FORMATS['.md']).to eq(:markdown)
      expect(described_class::EXTENSION_FORMATS['.html']).to eq(:html)
      expect(described_class::EXTENSION_FORMATS['.adoc']).to eq(:asciidoc)
      expect(described_class::EXTENSION_FORMATS['.docx']).to eq(:docx)
    end
  end

  describe 'BINARY_FORMATS' do
    it 'includes docx' do
      expect(described_class::BINARY_FORMATS).to include(:docx)
    end
  end

  describe '#convert' do
    context 'when converting to docx' do
      it 'rejects docx as target format' do
        expect do
          cli.options = { to: 'docx', verbose: false }
          cli.convert('/nonexistent/file.md')
        end.to raise_error(SystemExit)
      end
    end
  end

  # Helper to capture stdout
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  rescue SystemExit
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
