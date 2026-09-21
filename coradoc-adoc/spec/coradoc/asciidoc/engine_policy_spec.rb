# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AsciiDoc engine policy' do
  it 'parses on the Ruby engine by default (native pending parsanol-ruby#83)' do
    skip 'native tree parity landed' if ENV['CORADOC_ADOC_NATIVE'] == '1'

    parser = Coradoc::AsciiDoc::Parser::Base.new
    expect(parser).to be_native_expressible
    # The engine pin: without an explicit mode, parses must NOT run on
    # the native engine until parsanol-ruby#83 (tree-shape divergence,
    # OOM under concurrent native use) is resolved. Dropping this pin
    # without parity re-introduces silent wrong trees and host-crash
    # risk — see TODO.inhouseparsing/01.
    tree = parser.parse('== H')
    expect(tree).to include(:document)
  end
end
