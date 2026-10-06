# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AsciiDoc ruby-vs-native engine differential' do
  # parsanol 1.3.67: native tree parity is complete for this corpus
  # (21/21 constructs) and the historical nested_block regression no
  # longer reproduces. The engine default stays :ruby pending upstream
  # resource work: a full-suite native run was killed at 5.3 GB RSS,
  # rooted in the table grammar's catastrophic native backtracking
  # (parsanol-rs#174). This differential stays corpus-sized and cheap
  # (~3 s). Skipped on runners without the native extension.
  corpus = {
    'header+author+revision' => "= Title\nAuthor Name, 2026-01-01: v1 initial\n\n== Section\n\nText.\n",
    'nested sections' => "== H2\n\ntext\n\n=== H3\n\nmore\n",
    'unordered list' => "* one\n* two\n** nested\n* three\n",
    'ordered list' => ". first\n. second\n.. sub\n",
    'admonition' => "NOTE: important thing\n",
    'source block' => "[source,ruby]\n----\nputs 1\n----\n",
    'inline formatting+xref' => "See <<target,display>> and *bold* and _em_.\n",
    'definition list' => "term:: definition\n",
    'quote block' => "____\nquoted\n____\n",
    'block image w/ attrs' => "image::foo.png[Alt text, width=200]\n",
    'inline image' => "See image:foo.png[Alt].\n",
    'footnoteref' => "text footnoteref:[id1,Note text] end.\n",
    'bibliography entry' => "+++[bibliography]\n- [[[ref1]]] Reference One\n",
    'comments' => "// line comment\n\n////\nblock comment\n////\n\ntext\n",
    'page break' => "before\n\n<<<\n\nafter\n",
    'include directive' => "include::chapter.adoc[leveloffset=+1]\n",
    'stem inline' => "stem:[x^2 + y^2] inline math\n",
    'document attributes' => ":toc:\n:icons: font\n\ncontent\n",
    'open block' => "--\ninside open\n--\n",
    'list continuation' => "* item\n+\ncontinuation para\n",
    'styled paragraph' => "[.role-name]\nstyled text\n",
    'table' => "|===\n|A |B\n|1 |2\n|===\n"
  }

  before do
    skip 'parsanol native extension not available' unless Parsanol::Native.available?
  end

  corpus.each do |name, input|
    it "parses '#{name}' to identical trees on both engines" do
      ruby_tree = Coradoc::AsciiDoc::Parser::Base.new.parse(input, mode: :ruby)
      native_tree = Coradoc::AsciiDoc::Parser::Base.new.parse(input, mode: :native)
      expect(native_tree).to eq(ruby_tree)
    end
  end
end
