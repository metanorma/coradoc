# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Parser::FrontmatterParser do
  describe '.call' do
    it 'returns nil frontmatter and empty body for nil input' do
      result = described_class.call(nil)
      expect(result.frontmatter).to be_nil
      expect(result.body).to eq('')
    end

    it 'returns nil frontmatter and empty body for empty input' do
      result = described_class.call('')
      expect(result.frontmatter).to be_nil
      expect(result.body).to eq('')
    end

    it 'returns nil frontmatter when no opening delimiter' do
      result = described_class.call("# Just a heading\n")
      expect(result.frontmatter).to be_nil
      expect(result.body).to eq("# Just a heading\n")
    end

    it 'does not treat mid-document --- as frontmatter' do
      text = "# Heading\n\n---\n\ncontent\n"
      result = described_class.call(text)
      expect(result.frontmatter).to be_nil
      expect(result.body).to eq(text)
    end

    it 'splits a simple frontmatter block from body' do
      text = "---\ntitle: Hello\n---\n\n# Heading\n"
      result = described_class.call(text)
      expect(result.frontmatter).to eq("title: Hello\n")
      expect(result.body).to eq("# Heading\n")
    end

    it 'accepts the ... terminator' do
      text = "---\ntitle: Hello\n...\n\n# Heading\n"
      result = described_class.call(text)
      expect(result.frontmatter).to eq("title: Hello\n")
      expect(result.body).to eq("# Heading\n")
    end

    it 'preserves leading whitespace inside YAML' do
      yaml = "author:\n  name: Alice\n  email: a@x.com\n"
      text = "---\n#{yaml}---\n\nbody\n"
      result = described_class.call(text)
      expect(result.frontmatter).to eq(yaml)
    end

    it 'strips the leading blank line(s) after the close delimiter' do
      text = "---\nx: 1\n---\n\n\n\n# Body\n"
      result = described_class.call(text)
      expect(result.body).to eq("# Body\n")
    end

    it 'returns the body verbatim when only the opening delimiter is present' do
      text = "---\nx: 1\n"
      result = described_class.call(text)
      expect(result.frontmatter).to be_nil
      expect(result.body).to eq(text)
    end

    it 'handles an empty frontmatter block' do
      text = "---\n---\n\nbody\n"
      result = described_class.call(text)
      expect(result.frontmatter).to eq('')
      expect(result.body).to eq("body\n")
    end
  end

  describe 'Result#frontmatter?' do
    it 'is false when frontmatter is nil' do
      result = described_class::Result.new(frontmatter: nil, body: '')
      expect(result.frontmatter?).to be false
    end

    it 'is false when frontmatter is an empty string' do
      result = described_class::Result.new(frontmatter: '', body: '')
      expect(result.frontmatter?).to be false
    end

    it 'is true when frontmatter has content' do
      result = described_class::Result.new(frontmatter: "title: x\n", body: '')
      expect(result.frontmatter?).to be true
    end
  end
end
