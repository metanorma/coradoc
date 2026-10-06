# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AsciiDoc engine policy' do
  it 'parses on the native engine by default' do
    parser = Coradoc::AsciiDoc::Parser::Base.new
    expect(parser).to be_native_expressible
    # Flipped with parsanol >= 1.3.73 (crate 0.13.2): tree parity is
    # complete (engine_differential_spec, incl. tables) and the table
    # grammar's catastrophic native backtracking is fixed
    # (parsanol-rs#174). The Ruby engine stays available via
    # mode: :ruby and remains the parity reference.
    tree = parser.parse('== H')
    expect(tree).to include(:document)
  end

  it 'still reaches the Ruby engine when requested' do
    parser = Coradoc::AsciiDoc::Parser::Base.new
    tree = parser.parse('== H', mode: :ruby)
    expect(tree).to include(:document)
  end
end
