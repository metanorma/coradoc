# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Markdown ruby-vs-native inline-engine differential' do
  # The inline grammar is fully wire-expressible since the #163
  # restructure: callable transforms moved to the AST phase (raw
  # captures decoded in InlineParser#parse) and class-based guards
  # use Atoms::Lookbehind.regex (parsanol >= 1.3.77). parsanol's
  # default engine selection is native-when-expressible, so this
  # differential guards the native lane the suite now runs on.
  corpus = {
    'emphasis strong' => '**bold** and _em_ text',
    'code spans' => '`code` and ``double`` and ` x `',
    'entities' => 'a &amp; b &#65; &#x42; &#x1F600; &unknown;',
    'escapes' => '\\* not em \\_ and \\`code\\`',
    'flanking left' => 'left*flank*right and a**b**c',
    'flanking denied' => '*not em* because space * x',
    'nested emphasis' => '***both*** and **_mix_**',
    'nul byte' => "before \0 after"
  }

  before do
    skip 'parsanol native extension not available' unless Parsanol::Native.available?
  end

  def normalize(obj)
    case obj
    when Parsanol::Slice then obj.to_s
    when Hash then obj.transform_values { |v| normalize(v) }
    when Array then obj.map { |v| normalize(v) }
    else obj
    end
  end

  corpus.each do |name, input|
    it "parses '#{name}' to identical trees on both engines" do
      ruby_tree = normalize(Coradoc::Markdown::Parser::InlineParser.new.parse(input, mode: :ruby))
      native_tree = normalize(Coradoc::Markdown::Parser::InlineParser.new.parse(input, mode: :native))
      expect(native_tree).to eq(ruby_tree)
    end
  end
end
