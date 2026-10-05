# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AsciiDoc engine identity' do
  it 'builds on Parsanol::Parser' do
    expect(Coradoc::AsciiDoc::Parser::Base).to be < Parsanol::Parser
  end

  it 'parses through the Parsanol surface' do
    parser = Coradoc::AsciiDoc::Parser::Base.new
    expect(parser).to respond_to(:parse)
    expect(parser).to be_native_expressible
  end

  it 'has the native engine available (fails under REQUIRE_NATIVE=1)' do
    if ENV['REQUIRE_NATIVE'] == '1'
      expect(Parsanol::Native.available?).to be(true)
    elsif !Parsanol::Native.available?
      skip 'parsanol native ext not built; set REQUIRE_NATIVE=1 to require it'
    end
  end
end
