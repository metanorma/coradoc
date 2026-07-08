# frozen_string_literal: true

require 'spec_helper'

# Force autoload of Parser::List (it's autoloaded from Parser::Base, which
# only loads when a parser is instantiated). Without this, referencing
# LIST_BODY_INLINE_RULE_NAMES directly raises NameError.

RSpec.describe 'LIST_BODY_INLINE_RULE_NAMES drift detection' do
  let(:inline_order) { Coradoc::AsciiDoc::Parser::Inline::INLINE_RULE_ORDER }
  let(:body_rules) { Coradoc::AsciiDoc::Parser::List::LIST_BODY_INLINE_RULE_NAMES }

  it 'is a strict subset of INLINE_RULE_ORDER' do
    body_rules.each do |name|
      expect(inline_order).to include(name),
                              "LIST_BODY_INLINE_RULE_NAMES contains :#{name}, which is not in " \
                              'INLINE_RULE_ORDER. The constant is out of sync — update it.'
    end
  end

  it 'excludes hard_line_break (the rule that crosses newlines)' do
    expect(body_rules).not_to include(:hard_line_break)
  end

  it 'catches when INLINE_RULE_ORDER adds a new line-crossing rule' do
    # The diff between INLINE_RULE_ORDER and LIST_BODY_INLINE_RULE_NAMES
    # should be exactly the line-crossing rules (currently just
    # :hard_line_break). If a new diff appears, this test catches it and
    # prompts review: "did you add a new inline that crosses newlines?"
    diff = inline_order - body_rules
    expect(diff).to eq([:hard_line_break]),
                    "INLINE_RULE_ORDER - LIST_BODY_INLINE_RULE_NAMES = #{diff}. " \
                    'If you added a new inline rule that crosses newlines (consumes ' \
                    'a `\\n`), exclude it from LIST_BODY_INLINE_RULE_NAMES too ' \
                    'otherwise list_body_text_line will greedy-match across newlines ' \
                    'via that rule (same bug class as the original hard_line_break issue).'
  end

  it 'is frozen (single source of truth, not mutated at runtime)' do
    expect(body_rules).to be_frozen
  end
end
