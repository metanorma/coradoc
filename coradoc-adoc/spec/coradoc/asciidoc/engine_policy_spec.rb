# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AsciiDoc engine policy' do
  it 'parses on the Ruby engine by default' do
    skip 'native tree parity reached zero regressions' if ENV['CORADOC_ADOC_NATIVE'] == '1'

    parser = Coradoc::AsciiDoc::Parser::Base.new
    expect(parser).to be_native_expressible
    # Default surface stays the Ruby engine until native tree parity is
    # zero; on parsanol-ruby 1.3.45 (#83 fixed via CanFlatten port +
    # #84 memory bound) the native suite is at 1 known regression
    # (nested_block_spec:68 — block_image alternative fires before the
    # open_block continuation inside source-cast `--` blocks; the
    # Ruby engine's continuation chain suppresses it).
    tree = parser.parse('== H')
    expect(tree).to include(:document)
  end
end
