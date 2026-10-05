# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AsciiDoc engine policy' do
  it 'parses on the Ruby engine by default' do
    skip 'native tree parity reached zero regressions' if ENV['CORADOC_ADOC_NATIVE'] == '1'

    parser = Coradoc::AsciiDoc::Parser::Base.new
    expect(parser).to be_native_expressible
    # Default surface stays the Ruby engine. Tree parity against the
    # native engine is complete on parsanol 1.3.67 (see
    # engine_differential_spec — 21/21 always-on corpus constructs, and
    # the historical nested_block regression no longer reproduces). The
    # remaining blocker is native resource usage: the table grammar
    # triggers catastrophic backtracking (95 s / >2.9 GB RSS for a
    # 4-cell table; parsanol-rs#174), which balloons a full-suite
    # native run past 5 GB. Flip the default when that is fixed.
    tree = parser.parse('== H')
    expect(tree).to include(:document)
  end
end
