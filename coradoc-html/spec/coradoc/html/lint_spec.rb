# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Coradoc::Html::Lint do
  def lint(html)
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'doc.html')
      File.write(path, html)
      Coradoc::Lint.run(path)
    end
  end

  it 'registers the html rules' do
    expect(Coradoc::Lint.registry.rule_ids(:html))
      .to contain_exactly('HTML001', 'HTML002')
  end

  describe 'HTML001 heading levels' do
    it 'flags skipped levels' do
      violations = lint('<h1>A</h1><h3>B</h3>')

      expect(violations.map(&:rule_id)).to eq(%w[HTML001])
      expect(violations.first.message).to include('1 to 3')
    end

    it 'accepts single-step nesting' do
      expect(lint('<h1>A</h1><h2>B</h2>')).to be_empty
    end
  end

  describe 'HTML002 image alt' do
    it 'flags images without alt text' do
      violations = lint('<img src="x.png">')

      expect(violations.map(&:rule_id)).to eq(%w[HTML002])
      expect(violations.first.message).to include('x.png')
    end

    it 'accepts images with alt text' do
      expect(lint('<img src="x.png" alt="describe">')).to be_empty
    end
  end

  it 'reports clean documents as empty' do
    expect(lint('<h1>A</h1><h2>B</h2><img src="x.png" alt="ok">')).to be_empty
  end
end
