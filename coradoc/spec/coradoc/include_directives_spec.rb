# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'pathname'
require 'json'
require 'coradoc/asciidoc'
require 'coradoc-mirror'

# Parity spec for the +include::+ directive, validated against
# SPEC-include-directives-parity.md. Covers both the graph mode
# (Coradoc.parse — Include nodes survive as link edges) and the
# explicit flat mode (Coradoc.resolve_includes — Include nodes are
# spliced inline).
RSpec.describe 'include:: directives', :asciidoc do
  let(:main_adoc) { 'main.adoc' }

  def with_fixtures(name)
    Dir.mktmpdir("coradoc-include-#{name}-") do |dir|
      yield Pathname.new(dir)
    end
  end

  def write(dir, mapping)
    mapping.each do |rel, content|
      target = dir.join(rel)
      target.dirname.mkpath
      target.write(content)
    end
  end

  def parse_adoc(text)
    Coradoc.parse(text, format: :asciidoc)
  end

  def body_text(core_or_hash)
    hash = core_or_hash.is_a?(Hash) ? core_or_hash : mirror_json(core_or_hash)
    texts = []
    walker = ->(n) {
      texts << n['text'] if n['type'] == 'text'
      (n['content'] || []).each { |c| walker.call(c) }
    }
    walker.call(hash)
    texts.join
  end

  def mirror_json(core)
    JSON.parse(Coradoc.serialize(core, to: :mirror_json))
  end

  def all_types(core_or_hash)
    hash = core_or_hash.is_a?(Hash) ? core_or_hash : mirror_json(core_or_hash)
    types = []
    walker = ->(n) {
      types << n['type']
      (n['content'] || []).each { |c| walker.call(c) }
    }
    walker.call(hash)
    types
  end

  # ── Mode 2: Graph-mode AST preservation ──

  describe 'graph mode (Coradoc.parse — no I/O)' do
    it 'emits an Include node for an include directive' do
      core = parse_adoc("Before.\n\ninclude::snippet.adoc[]\n\nAfter.\n")

      types = all_types(core)
      expect(types).to include('include')
    end

    it 'does not perform file I/O for a missing target' do
      expect {
        parse_adoc("include::does_not_exist.adoc[]\n")
      }.not_to raise_error
    end

    it 'round-trips the include directive through adoc serialization' do
      core = parse_adoc("Before.\n\ninclude::snippet.adoc[tags=body,leveloffset=+2]\n\nAfter.\n")
      expect(Coradoc.serialize(core, to: :asciidoc))
        .to eq("Before.\n\ninclude::snippet.adoc[tags=body,leveloffset=+2]\n\nAfter.")
    end

    it 'preserves raw_options verbatim for round-trip' do
      core = parse_adoc("include::x.adoc[tags=a;b,lines=1..3,indent=2,leveloffset=+1]\n")
      include_node = core.children.find { |c| c.is_a?(Coradoc::CoreModel::Include) }
      expect(include_node.raw_options).to eq('tags=a;b,lines=1..3,indent=2,leveloffset=+1')
    end
  end

  # ── Mode 1: flat-mode resolution via Coradoc.resolve_includes ──

  describe 'flat mode (Coradoc.resolve_includes — explicit step)' do
    it 'does not mutate the parsed document' do
      with_fixtures('immutability') do |dir|
        write(dir, 'main.adoc' => "Before.\n\ninclude::snippet.adoc[]\n\nAfter.\n",
                    'snippet.adoc' => "Included content.\n")

        core = parse_adoc(dir.join('main.adoc').read)
        original_types = all_types(core)

        _ = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        expect(all_types(core)).to eq(original_types)
      end
    end

    it 'resolves a whole-file include' do
      with_fixtures('whole_file') do |dir|
        write(dir, 'main.adoc' => "Before.\n\ninclude::snippet.adoc[]\n\nAfter.\n",
                    'snippet.adoc' => "Included content.\n")

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        expect(body_text(flat)).to eq('Before.Included content.After.')
      end
    end

    it 'resolves relative subdirectory paths' do
      with_fixtures('rel_path') do |dir|
        write(dir, 'main.adoc' => "include::sections/intro.adoc[]\n",
                    'sections/intro.adoc' => "Intro body.\n")

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        expect(body_text(flat)).to eq('Intro body.')
      end
    end

    it 'resolves paths that traverse parent directories (with allow_unsafe)' do
      with_fixtures('parent_path') do |dir|
        write(dir, 'sub/main.adoc' => "include::../shared.adoc[]\n",
                    'shared.adoc' => "Shared body.\n")

        core = parse_adoc(dir.join('sub/main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.join('sub').to_s,
                                              allow_unsafe: true)
        expect(body_text(flat)).to eq('Shared body.')
      end
    end

    it 'resolves multiple consecutive includes in source order' do
      with_fixtures('multiple') do |dir|
        write(dir, 'main.adoc' => "include::a.adoc[]\ninclude::b.adoc[]\ninclude::c.adoc[]\n",
                    'a.adoc' => "A-body.\n",
                    'b.adoc' => "B-body.\n",
                    'c.adoc' => "C-body.\n")

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        expect(body_text(flat)).to eq('A-body.B-body.C-body.')
      end
    end

    it 'resolves an include at the start of the document' do
      with_fixtures('leading') do |dir|
        write(dir, 'main.adoc' => "include::snippet.adoc[]\n\nTrailing.\n",
                    'snippet.adoc' => "Leading body.\n")

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        expect(body_text(flat)).to eq('Leading body.Trailing.')
      end
    end

    it 'resolves an include at the end of the document' do
      with_fixtures('trailing') do |dir|
        write(dir, 'main.adoc' => "Leading.\n\ninclude::snippet.adoc[]\n",
                    'snippet.adoc' => "Trailing body.\n")

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        expect(body_text(flat)).to eq('Leading.Trailing body.')
      end
    end
  end

  # ── Tag-based selection ──

  describe 'tags= selection' do
    it 'extracts a single named tag region' do
      with_fixtures('tag_single') do |dir|
        write(dir, 'main.adoc' => "include::snippet.adoc[tags=body]\n",
                    'snippet.adoc' => "// tag::body[]\nIncluded body.\n// end::body[]\n")

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        expect(body_text(flat)).to eq('Included body.')
      end
    end

    it 'extracts multiple semicolon-separated tags' do
      with_fixtures('tag_multi') do |dir|
        write(dir, 'main.adoc' => "include::snippet.adoc[tags=intro;conclusion]\n",
                    'snippet.adoc' => %(// tag::intro[]\nIntro body.\n// end::intro[]\n\nmiddle\n\n// tag::conclusion[]\nConclusion body.\n// end::conclusion[]\n))

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        text = body_text(flat)
        expect(text).to include('Intro body.')
        expect(text).to include('Conclusion body.')
        expect(text).not_to include('middle')
      end
    end

    it 'treats tags=* as wildcard selecting all tagged regions' do
      with_fixtures('tag_wildcard') do |dir|
        write(dir, 'main.adoc' => "include::snippet.adoc[tags=*]\n",
                    'snippet.adoc' => %(outside\n\n// tag::a[]\nA body.\n// end::a[]\n\nbetween\n\n// tag::b[]\nB body.\n// end::b[]\n))

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        text = body_text(flat)
        expect(text).to include('A body.')
        expect(text).to include('B body.')
        expect(text).not_to include('outside')
        expect(text).not_to include('between')
      end
    end

    it 'treats tags=** as inverted wildcard excluding tagged regions' do
      with_fixtures('tag_inverted') do |dir|
        write(dir, 'main.adoc' => "include::snippet.adoc[tags=**]\n",
                    'snippet.adoc' => %(
outside-tagged

// tag::a[]
A body.
// end::a[]
).lstrip)

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        expect(body_text(flat)).to include('outside-tagged')
        expect(body_text(flat)).not_to include('A body.')
      end
    end

    it 'yields empty content for an unknown tag name' do
      with_fixtures('tag_unknown') do |dir|
        write(dir, 'main.adoc' => "Before.\n\ninclude::snippet.adoc[tags=nonexistent]\n\nAfter.\n",
                    'snippet.adoc' => "// tag::real[]\nbody\n// end::real[]\n")

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        expect(body_text(flat)).to eq('Before.After.')
      end
    end

    it 'does not emit the tag markers as text' do
      with_fixtures('tag_no_markers') do |dir|
        write(dir, 'main.adoc' => "include::snippet.adoc[tags=body]\n",
                    'snippet.adoc' => "// tag::body[]\ninside\n// end::body[]\n")

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        text = body_text(flat)
        expect(text).not_to include('tag::')
        expect(text).not_to include('end::')
      end
    end
  end

  # ── Line-based selection ──

  describe 'lines= selection' do
    it 'extracts a single line by number' do
      with_fixtures('lines_single') do |dir|
        snippet = "L1\nL2\nL3\nL4\nL5\n"
        write(dir, 'main.adoc' => "include::snippet.adoc[lines=2]\n",
                    'snippet.adoc' => snippet)

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        expect(body_text(flat)).to eq('L2')
      end
    end

    it 'extracts a line range' do
      with_fixtures('lines_range') do |dir|
        snippet = "L1\nL2\nL3\nL4\nL5\n"
        write(dir, 'main.adoc' => "include::snippet.adoc[lines=2..4]\n",
                    'snippet.adoc' => snippet)

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        text = body_text(flat)
        expect(text).to include('L2', 'L3', 'L4')
        expect(text).not_to include('L1', 'L5')
      end
    end

    it 'extracts discontinuous ranges (semicolon-separated)' do
      with_fixtures('lines_discontinuous') do |dir|
        snippet = "L1\nL2\nL3\nL4\nL5\n"
        write(dir, 'main.adoc' => "include::snippet.adoc[lines=1..2;5]\n",
                    'snippet.adoc' => snippet)

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        text = body_text(flat)
        expect(text).to include('L1', 'L2', 'L5')
        expect(text).not_to include('L3', 'L4')
      end
    end

    it 'clamps out-of-bounds ranges gracefully' do
      with_fixtures('lines_oob') do |dir|
        snippet = "L1\nL2\nL3\n"
        write(dir, 'main.adoc' => "include::snippet.adoc[lines=2..99]\n",
                    'snippet.adoc' => snippet)

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        text = body_text(flat)
        expect(text).to include('L2', 'L3')
        expect(text).not_to include('L1')
      end
    end
  end

  # ── Indentation ──

  describe 'indent= selection' do
    it 'strips all leading whitespace when indent=0' do
      with_fixtures('indent_zero') do |dir|
        snippet = "    indented line one\n    indented line two\n"
        write(dir, 'main.adoc' => "include::snippet.adoc[indent=0]\n",
                    'snippet.adoc' => snippet)

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        text = body_text(flat)
        expect(text).to include('indented line one')
        expect(text).not_to match(/^\s+\S/)
      end
    end
  end

  # ── Recursion ──

  describe 'recursive resolution' do
    it 'resolves nested includes recursively' do
      with_fixtures('nested') do |dir|
        write(dir, 'main.adoc' => "Top.\n\ninclude::a.adoc[]\n",
                    'a.adoc' => "A.\n\ninclude::b.adoc[]\n",
                    'b.adoc' => "B body.\n")

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        expect(body_text(flat)).to eq('Top.A.B body.')
      end
    end

    it 'resolves recursive includes relative to the including file' do
      with_fixtures('nested_relative') do |dir|
        write(dir, 'main.adoc' => "include::sub/a.adoc[]\n",
                    'sub/a.adoc' => "A.\n\ninclude::b.adoc[]\n",
                    'sub/b.adoc' => "B body.\n")

        core = parse_adoc(dir.join('main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

        expect(body_text(flat)).to eq('A.B body.')
      end
    end

    it 'detects circular includes' do
      with_fixtures('circular') do |dir|
        write(dir, 'main.adoc' => "include::a.adoc[]\n",
                    'a.adoc' => "include::b.adoc[]\n",
                    'b.adoc' => "include::a.adoc[]\n")

        core = parse_adoc(dir.join('main.adoc').read)
        expect {
          Coradoc.resolve_includes(core, base_dir: dir.to_s)
        }.to raise_error(Coradoc::CircularIncludeError)
      end
    end

    it 'detects self-including files' do
      with_fixtures('self_include') do |dir|
        write(dir, 'main.adoc' => "include::main.adoc[]\n")

        core = parse_adoc(dir.join('main.adoc').read)
        expect {
          Coradoc.resolve_includes(core, base_dir: dir.to_s)
        }.to raise_error(Coradoc::CircularIncludeError)
      end
    end

    it 'respects the configured max depth' do
      with_fixtures('max_depth') do |dir|
        write(dir, 'main.adoc' => "include::a.adoc[]\n",
                    'a.adoc' => "include::b.adoc[]\n",
                    'b.adoc' => "B body.\n")

        core = parse_adoc(dir.join('main.adoc').read)
        expect {
          Coradoc.resolve_includes(core, base_dir: dir.to_s, max_depth: 1)
        }.to raise_error(Coradoc::IncludeDepthExceededError)
      end
    end
  end

  # ── Missing-file handling ──

  describe 'missing_include policy' do
    before do
      @core = parse_adoc("Before.\n\ninclude::missing.adoc[]\n\nAfter.\n")
    end

    describe 'line-ending normalization (Windows parity)' do
      it 'parses CRLF line endings in resolved includes' do
        with_fixtures('crlf') do |dir|
          # Write fixture in binary mode with explicit CRLF to simulate
          # files produced on Windows. The resolver must normalize CRLF
          # → LF before handing content to the parser, matching
          # asciidoctor's line-ending normalization.
          File.binwrite(dir.join('snippet.adoc'), "Included content.\r\n")

          core = parse_adoc("Before.\n\ninclude::snippet.adoc[]\n\nAfter.\n")
          flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

          expect(body_text(flat)).to eq('Before.Included content.After.')
        end
      end

      it 'parses CRLF line endings in nested includes' do
        with_fixtures('crlf_nested') do |dir|
          # main.adoc has clean LF (matches `Pathname#read` text-mode
          # translation on Windows). a.adoc/b.adoc have CRLF on disk,
          # matching what File.binread in the resolver returns before
          # normalization.
          dir.join('main.adoc').write("Top.\n\ninclude::a.adoc[]\n")
          File.binwrite(dir.join('a.adoc'), "A.\r\n\r\ninclude::b.adoc[]\r\n")
          File.binwrite(dir.join('b.adoc'), "B body.\r\n")

          core = parse_adoc(dir.join('main.adoc').read)
          flat = Coradoc.resolve_includes(core, base_dir: dir.to_s)

          expect(body_text(flat)).to eq('Top.A.B body.')
        end
      end
    end

    it 'raises by default' do
      expect {
        Coradoc.resolve_includes(@core, base_dir: Dir.tmpdir)
      }.to raise_error(Coradoc::IncludeNotFoundError)
    end

    it 'warns and skips when :warn' do
      expect(Coradoc::Logger).to receive(:warn).with(/Include target not found/)

      flat = Coradoc.resolve_includes(@core, base_dir: Dir.tmpdir, missing_include: :warn)
      expect(body_text(flat)).to eq('Before.After.')
    end

    it 'is silent when :silent' do
      expect(Coradoc::Logger).not_to receive(:warn)

      flat = Coradoc.resolve_includes(@core, base_dir: Dir.tmpdir, missing_include: :silent)
      expect(body_text(flat)).to eq('Before.After.')
    end

    it 'leaves the directive in place when :passthrough' do
      flat = Coradoc.resolve_includes(@core, base_dir: Dir.tmpdir, missing_include: :passthrough)
      expect(all_types(flat)).to include('include')
    end
  end

  # ── Path security ──

  describe 'path traversal protection' do
    it 'blocks .. that escapes the base_dir by default' do
      with_fixtures('traversal') do |dir|
        write(dir, 'sub/main.adoc' => "include::../secret.adoc[]\n",
                    'secret.adoc' => "SECRET\n")

        core = parse_adoc(dir.join('sub/main.adoc').read)
        expect {
          Coradoc.resolve_includes(core, base_dir: dir.join('sub').to_s)
        }.to raise_error(Coradoc::UnsafeIncludeError)
      end
    end

    it 'allows .. when explicitly enabled' do
      with_fixtures('traversal_allowed') do |dir|
        write(dir, 'sub/main.adoc' => "include::../secret.adoc[]\n",
                    'secret.adoc' => "SECRET\n")

        core = parse_adoc(dir.join('sub/main.adoc').read)
        flat = Coradoc.resolve_includes(core, base_dir: dir.join('sub').to_s,
                                              allow_unsafe: true)
        expect(body_text(flat)).to eq('SECRET')
      end
    end
  end

  # ── Custom resolver ──

  describe 'custom resolver' do
    it 'invokes the resolver with parsed options' do
      calls = []
      resolver = Object.new
      def resolver.call(target:, base_dir:, options:, context:)
        self.calls << { target: target, options_tags: options.tags }
        "from-resolver\n"
      end

      # Stub the calls capture via a wrapper
      captured_calls = calls
      real_resolver = Object.new
      real_resolver.define_singleton_method(:call) do |target:, base_dir:, options:, context:|
        captured_calls << { target: target, tags: options.tags }
        "from-resolver\n"
      end

      core = parse_adoc("include::custom.adoc[]\n")
      flat = Coradoc.resolve_includes(core, base_dir: '/tmp', resolver: real_resolver)

      expect(captured_calls.length).to eq(1)
      expect(captured_calls.first[:target]).to eq('custom.adoc')
      expect(body_text(flat)).to include('from-resolver')
    end

    it 'passes the parsed options through to the resolver' do
      captured = nil
      resolver = Object.new
      resolver.define_singleton_method(:call) do |target:, base_dir:, options:, context:|
        captured = options
        "body\n"
      end

      core = parse_adoc("include::custom.adoc[tags=body;intro,lines=1..5]\n")
      Coradoc.resolve_includes(core, base_dir: '/tmp', resolver: resolver)

      expect(captured).to be_a(Coradoc::CoreModel::IncludeOptions)
      expect(captured.tags).to eq(%w[body intro])
      expect(captured.lines_spec).to eq('1..5')
    end

    it 'routes missing-target errors through the missing_include policy' do
      resolver = Object.new
      def resolver.call(target:, base_dir:, options:, context:)
        raise Coradoc::IncludeNotFoundError.new(target: target)
      end

      core = parse_adoc("include::missing.adoc[]\n")

      expect(Coradoc::Logger).to receive(:warn).with(/Include target not found/)
      flat = Coradoc.resolve_includes(core, base_dir: '/tmp',
                                             missing_include: :warn,
                                             resolver: resolver)
      expect(body_text(flat)).to eq('')
    end
  end
end
