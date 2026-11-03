# frozen_string_literal: true

module Coradoc
  module Roundtrip
    # Generated edge-case corpus: small constructs that fixture files rarely
    # isolate. Each entry is [name, source text].
    module EdgeCases
      ASCIIDOC = {
        'empty' => '',
        'blank-lines-only' => "\n\n\n",
        'title-only' => "= Title\n",
        'paragraph-no-trailing-newline' => 'Just text',
        'unicode' => "= Ünïcødé\n\nSnowman ☃ and 日本語 and emoji 🙂.\n",
        'nested-sections' => "= T\n\n== A\n\n=== B\n\n==== C\n\ntext\n",
        'nested-unordered' => "* a\n** b\n*** c\n* d\n",
        'nested-ordered' => ". a\n.. b\n... c\n. d\n",
        'definition-list' => "term:: definition\nother:: more\n",
        'listing-block' => "[source,ruby]\n----\nputs 1\n----\n",
        'admonition' => "NOTE: be careful\n",
        'table' => "|===\n|a |b\n\n|1 |2\n|===\n",
        'inline-markup' => "Some *bold*, _italic_, `mono`, and ^sup^ ~sub~.\n",
        'link-and-xref' => "https://example.com[Example] and <<anchor,text>>.\n",
        'attribute-entry' => ":author: Someone\n\ntext {author}\n"
      }.freeze

      MARKDOWN = {
        'empty' => '',
        'blank-lines-only' => "\n\n\n",
        'paragraph-no-trailing-newline' => 'Just text',
        'unicode' => "# Ünïcødé\n\nSnowman ☃ and 日本語 and emoji 🙂.\n",
        'atx-levels' => "# 1\n\n## 2\n\n### 3\n\n###### 6\n",
        'setext' => "Title\n=====\n\nSub\n---\n",
        'nested-unordered' => "- a\n    - b\n        - c\n- d\n",
        'ordered-start' => "3. three\n4. four\n",
        'fenced-code' => "```ruby\nputs 1\n```\n",
        'blockquote' => "> quoted\n> more\n",
        'emphasis-markers' => "*a* _b_ **c** __d__ `e`\n",
        'link-and-image' => "[t](https://example.com \"title\") ![alt](x.png)\n",
        'table' => "| a | b |\n|---|---|\n| 1 | 2 |\n",
        'hard-break' => "line one  \nline two\n",
        'horizontal-rule' => "a\n\n---\n\nb\n",
        'frontmatter' => "---\ntitle: T\n---\n\n# H\n"
      }.freeze

      module_function

      # @return [Array<Case>]
      def all
        { asciidoc: ASCIIDOC, markdown: MARKDOWN }.flat_map do |format, table|
          table.map { |name, text| Case.new("#{format}:edge/#{name}", format, text, 'edge case') }
        end
      end
    end
  end
end
