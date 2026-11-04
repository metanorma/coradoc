# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/legacy_transformer'

RSpec.describe 'Markdown bound-vs-legacy differential (BindingInflater vs the frozen hand-written transformer)' do
  def inflater
    Coradoc::Markdown::Bindings.inflater
  end

  # The retired hand-written stage-1 -> 2 path (spec/support).
  def legacy_parse(input)
    split = Coradoc::Markdown::Parser::FrontmatterParser.call(input)
    ast = Coradoc::Markdown::Parser::BlockParser.new.parse(split.body)
    doc = Coradoc::Markdown::LegacyTransformer.transform_document(ast)
    doc.frontmatter = split.frontmatter if split.frontmatter?
    doc
  end

  def self.fixture_paths
    repo_root = File.expand_path('../../../..', __dir__)
    Dir[File.expand_path('../../fixtures/**/*.text', __dir__)] +
      Dir[File.join(repo_root, 'BUGREPORT.model-driven', '*.md')]
  end

  # Block quotes flatten child models with #to_s, which prints the class
  # and object address; compare modulo both.
  def comparable(doc)
    doc.to_yaml.gsub(/#<Coradoc::Markdown::(?:Generated::)?(\w+):0x\h+>/, '#<\\1>')
  end

  def contains_rule?(node, key)
    case node
    when Hash then node.key?(key) || node.each_value.any? { |v| contains_rule?(v, key) }
    when Array then node.any? { |v| contains_rule?(v, key) }
    else false
    end
  end

  def blocks_of(doc, klass)
    doc.blocks.select { |b| b.instance_of?(klass) }
  end

  it 'binds the thematic break to the active model class' do
    doc = Coradoc::Markdown.parse("para\n\n---\n\nafter\n", bindings: inflater)
    rules = blocks_of(doc, Coradoc::Markdown::HorizontalRule)
    expect(rules.map(&:style)).to eq(['---'])
  end

  it 'binds every block rule to the active model classes' do
    input = <<~MD
      # Title

      para *em*

      - a
      - b

      1. one

      ```ruby
      puts 1
      ```

      > quote

      | h1 | h2 |
      | -- | -- |
      | a  | b  |

      term
      : def

      [^n]: note

      *[MD]: Markdown
    MD
    doc = Coradoc::Markdown.parse(input, bindings: inflater)
    expect(doc.blocks.map { |b| b.class.name.split('::').last }).to include(
      'Heading', 'Paragraph', 'List', 'CodeBlock', 'Blockquote', 'Table', 'DefinitionList', 'Footnote',
      'Abbreviation'
    )
  end

  it 'binds by default, with no bindings option' do
    doc = Coradoc::Markdown.parse("para\n\n---\n")
    expect(blocks_of(doc, Coradoc::Markdown::HorizontalRule).size).to eq(1)
    expect(Coradoc::Markdown::Transformer.bindings).to be(inflater)
  end

  it 'binds the stateful rules (ALD definition, IAL reference) through scoped hooks' do
    input = "{:ref: .note}\n\npara\n\n{:ref}\n\n{: .fresh}\n"
    expect(comparable(Coradoc::Markdown.parse(input, bindings: inflater)))
      .to eq(comparable(legacy_parse(input)))
    expect(inflater.bound?({ ald_name: 'ref:', ial: '.note' })).to be(true)
    expect(inflater.bound?({ ial: 'ref' })).to be(true)
  end

  it 'resolves an IAL reference against its own document\'s ALD table only' do
    ald = { ald_name: 'ref', ial: '.note' }
    ref = { ial: 'ref' }
    same = Coradoc::Markdown::Transformer.transform_document([ald, ref])
    other = Coradoc::Markdown::Transformer.transform_document([ref])
    expect(same.blocks.first.name).to eq('ref')
    expect(other.blocks.first.name).to be_nil
  end

  # The hand-written transformer's standalone-IAL branch shadowed a code
  # block or block quote that carries an IAL (it returned the bare
  # attribute list and dropped the block). The bindings attach the IAL.
  it 'attaches an IAL to a code block and a block quote instead of shadowing them' do
    code = Coradoc::Markdown::Transformer.transform_element({ code_block: [{ ln: 'x' }], ial: '#a .b' })
    quote = Coradoc::Markdown::Transformer.transform_element({ block_quote: { p: { ln: 'q' } }, ial: '.c' })
    expect(code).to be_a(Coradoc::Markdown::CodeBlock)
    expect(code.id).to eq('a')
    expect(quote).to be_a(Coradoc::Markdown::Blockquote)
    expect(quote.classes).to eq(['c'])
  end

  it 'reaches bound rules nested in containers' do
    doc = Coradoc::Markdown.parse("> a\n>\n> ---\n", bindings: inflater)
    expect(comparable(doc)).to eq(comparable(legacy_parse("> a\n>\n> ---\n")))
  end

  # Raw nodes the block parser does not currently emit (or emits only
  # with trailing attribute lists): bound and hand-written must agree.
  {
    'ATX heading with an IAL' => { heading: '##', text: 'Title', ial: '#id .cls key="v"' },
    'empty heading with an IAL' => { heading: '#', ial: '.cls' },
    'setext heading' => { heading: '===', text: [{ ln: 'one' }, { ln: 'two' }] },
    'paragraph with an IAL' => { p: [{ ln: 'a *b*' }, { ln: 'c' }], ial: '.p' },
    'bare line' => { ln: 'just text' },
    'bare text' => { text: 'plain' },
    'nested lists' => { ul: [{ li: [{ p: { ln: 'a' } }, { ol: [{ li: { p: { ln: 'b' } } }] }] }] },
    'single-item list' => { ol: { li: { p: { ln: 'only' } } } },
    'header-only table' => { table_header: { row: { cell: 'h', row_rest: [], last_cell: { cell: 'i' } } },
                             table_separator: { sep: '--' } },
    'footnote without continuation' => { fn_id: 'n', fn_content: { ln: 'text' } },
    'footnote reference' => { fn_ref: 'n' },
    'bare extension' => { ext_name: 'toc', ext_options: [] },
    'bare extension with body' => { ext_name: 'c', ext_options: 'a=1', ext_body: 'body' },
    'block math' => { math_content: ' x^2 ' }
  }.each do |name, node|
    it "inflates the raw #{name} like the hand-written transformer" do
      bound = Coradoc::Markdown::Transformer.transform_element(node)
      unbound = Coradoc::Markdown::LegacyTransformer.transform_element(node)
      expect(inflater.bound?(node)).to be(true)
      expect(bound.class).to eq(unbound.class)
      expect(comparable(bound)).to eq(comparable(unbound))
    end
  end

  # The block parser yields only these inline shapes inside paragraphs;
  # the paragraph's children must match the hand-written inline models.
  it 'builds identical inline children for emphasis, strong and code, nested and across lines' do
    ['a *em* and **strong** and `code`', "line one\nline *two*\nthree", '***both*** and `x` and **a *b* c**'].each do |input|
      expect(comparable(Coradoc::Markdown.parse(input, bindings: inflater)))
        .to eq(comparable(legacy_parse(input))), input
    end
  end

  it 'binds every rule shape the corpus emits (guards against a rule silently going unbound)' do
    shapes = %i[heading p ul ol code_block block_quote dl table_header fn_id abbr_term extension hr].to_h { |k| [k, 0] }
    self.class.fixture_paths.each do |path|
      ast = Coradoc::Markdown.parse_ast(File.read(path))
      (ast.is_a?(Array) ? ast : [ast]).grep(Hash).each do |node|
        shapes.each_key { |key| shapes[key] += 1 if node.key?(key) && inflater.bound?(node) }
      end
    end
    expect(shapes.select { |_, hits| hits.zero? }.keys).to eq([])
  end

  it 'leaves a bare inline node unbound as a block' do
    expect(inflater.bound?({ strong: 'x' })).to be(false)
    expect(Coradoc::Markdown::Bindings.inline_inflater.bound?({ strong: 'x' })).to be(true)
  end

  it 'exercises the bound path over the corpus (guards against a vacuous run)' do
    hits = self.class.fixture_paths.count do |path|
      contains_rule?(Coradoc::Markdown.parse_ast(File.read(path)), :hr)
    end
    expect(hits).to be >= 4
  end

  {
    'dashes' => "a\n\n---\n\nb\n",
    'stars' => "***\n",
    'underscores' => "_ _ _\n\ntext\n",
    'after a list' => "- a\n- b\n\n---\n",
    'with an attribute list' => "---\n{:.rule}\n"
  }.each do |name, input|
    it "produces identical output for inline '#{name}'" do
      expect(comparable(Coradoc::Markdown.parse(input, bindings: inflater))).to eq(comparable(legacy_parse(input)))
    end
  end

  fixture_paths.each do |path|
    it "produces identical output for #{path.sub(%r{.*?/(coradoc-markdown|BUGREPORT)}, '\\1')}" do
      input = File.read(path)
      unbound = legacy_parse(input)
      bound = Coradoc::Markdown.parse(input, bindings: inflater)
      expect(comparable(bound)).to eq(comparable(unbound))
    end
  end
end

RSpec.describe 'Markdown bindings embedded in the artifact (M4)' do
  it 'ships the sidecar table inside the compiled artifact' do
    table = Coradoc::Markdown::Parser::Grammar.model_bindings
    expect(table['version']).to eq(1)
    expect(table['rules'].fetch('thematic_break')).to include('keys' => ['hr'], 'model' => 'HorizontalRule')
  end

  it 'keeps the artifact table equal to the sidecar source' do
    sidecar = YAML.safe_load_file(Coradoc::Markdown::Parser::Grammar::BINDINGS_PATH)
    embedded = Coradoc::Markdown::Parser::Grammar.model_bindings
    expect(embedded['rules'].transform_values { |r| r.slice(*sidecar['rules'].values.first.keys) })
      .to eq(sidecar['rules'])
  end

  it 'inflates a thematic break from the embedded table' do
    node = Coradoc::Markdown::Bindings.inflater.inflate({ hr: true }) { raise 'residual reached' }
    expect(node).to be_a(Coradoc::Markdown::HorizontalRule)
    expect(node.style).to eq('---')
  end
end
