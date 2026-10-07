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

  # Scope/continuation and lazy-continuation shapes. Un-gated as of
  # parsanol 1.3.79 (crate 0.17.2): rs#201 replaced the unmarked
  # host-atom registry with a GC-marked one, ending the linux x86_64
  # segfault in scope-shape replay (parsanol-ruby#177).
  corpus.merge!(
    'block quote' => "> quoted\n> more\n",
    'thematic break' => "para\n\n---\n\nafter\n",
    'paragraphs' => "one\n\ntwo\n\nthree\n",
    'lazy quote continuation' => "> bar\nbaz\n",
    'lazy nested quote' => "> > > foo\nbar\n",
    'lazy setext in quote' => "> foo\nbar\n===\n"
  )

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
end
