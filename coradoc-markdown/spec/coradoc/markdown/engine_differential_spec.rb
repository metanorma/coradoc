# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Markdown ruby-vs-native block-engine differential' do
  # BlockParser defaults to native (parsanol >= 1.3.75); this spec
  # keeps both engines honest over representative block constructs.
  # InlineParser is Ruby-pinned (DynamicOutput callables + class-based
  # lookbehind are not yet wire-expressible) and has no native lane.
  corpus = {
    'heading' => "# Title\n\npara\n",
    'setext heading' => "Title\n=====\n",
    'unordered list' => "- a\n- b\n  - nested\n",
    'ordered list' => "1. one\n2. two\n",
    'fenced code' => "```ruby\nputs 1\n```\n",
    'indented code' => "    code line\n    another\n",
    'table' => "| a | b |\n|---|---|\n| 1 | 2 |\n",
    'ial' => "para {:.cls #id}\n",
    'list continuation' => "- item\n\n  continued para\n",
    'html block' => "<div>\nraw\n</div>\n"
  }

  # KNOWN GAPS — native scope/continuation divergences (skip until
  # fixed upstream; reported to parsanol): block-quote markers leak
  # into line captures; blank-line/thematic-break structures collapse
  # into single paragraphs with empty {ln: []} entries.
  divergent_corpus = {
    'block quote' => "> quoted\n> more\n",
    'thematic break' => "para\n\n---\n\nafter\n",
    'paragraphs' => "one\n\ntwo\n\nthree\n"
  }

  before do
    skip 'parsanol native extension not available' unless Parsanol::Native.available?
  end

  corpus.each do |name, input|
    it "parses '#{name}' to identical trees on both engines" do
      ruby_tree = Coradoc::Markdown::Parser::BlockParser.new.parse(input, mode: :ruby)
      native_tree = Coradoc::Markdown::Parser::BlockParser.new.parse(input, mode: :native)
      expect(native_tree).to eq(ruby_tree)
    end
  end

  divergent_corpus.each do |name, input|
    it "parses '#{name}' to identical trees on both engines (known native gap: lazy continuation)" do
      skip 'native lazy-continuation divergence — parsanol-ruby#160' unless ENV['MARKDOWN_NATIVE_GAPS'] == '1'

      ruby_tree = Coradoc::Markdown::Parser::BlockParser.new.parse(input, mode: :ruby)
      native_tree = Coradoc::Markdown::Parser::BlockParser.new.parse(input, mode: :native)
      expect(native_tree).to eq(ruby_tree)
    end
  end
end
