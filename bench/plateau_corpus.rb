# frozen_string_literal: true

# Plateau-corpus parse benchmark (coradoc#308 acceptance).
#
#   ruby bench/plateau_corpus.rb CORPUS_DIR OUT.json
#
# Run once per checkout (OLD / NEW) with that checkout's gems on the load
# path; compare with bench/compare.rb. Times, per file: stage 1 (grammar
# -> AST), stage 2 (AST -> AsciiDoc model), and model -> CoreModel. Also
# records a digest of each stage's output so identity can be compared.
require 'json'
require 'digest'
require 'coradoc'
require 'coradoc/asciidoc'

dir, out = ARGV
max = Integer(ENV.fetch('MAX_BYTES', 250_000))
all = Dir.glob(File.join(dir, '**/*.adoc'))
files = all.select { |f| File.size(f) <= max }
if ENV['CHUNK'] # "i/n": process every n-th file starting at i, so a driver can bound memory per process
  i, n = ENV['CHUNK'].split('/').map(&:to_i)
  files = files.each_slice(n).map { |sl| sl[i] }.compact
end
warn "skipping #{(all - files).size} files > #{max} bytes"
A = Coradoc::AsciiDoc

def dump(obj)
  obj.respond_to?(:to_yaml) ? obj.to_yaml : obj.inspect
rescue StandardError => e
  "dump-error: #{e.class}"
end

# Digest of the dump with Parser::PositionedString (a String carrying its
# whole source_input) collapsed to its plain text, so that representation
# leakage can be told apart from a content difference.
def normalized(obj)
  require 'yaml'
  walk = lambda do |n|
    if n.is_a?(Psych::Nodes::Mapping) && n.tag.to_s.end_with?('PositionedString')
      i = n.children.each_slice(2).find { |k, _| k.value == 'str' }
      return i ? i[1] : n
    end
    n.children&.map! { |c| walk.call(c) }
    n
  end
  walk.call(Psych.parse_stream(dump(obj).gsub(/0x\h+/, ''))).to_yaml
rescue StandardError => e
  "norm-error: #{e.class}"
end

def clock = Process.clock_gettime(Process::CLOCK_MONOTONIC)

def measure(text)
  r = { 'bytes' => text.bytesize }
  t = clock
  split = A::Parser::FrontmatterParser.call(text)
  ast = A::Parser::Base.parse(split.body)
  r['s1'] = clock - t
  r['ast'] = Digest::SHA1.hexdigest(ast.inspect.gsub(/0x\h+/, ''))
  t = clock
  doc = A::Transformer.transform(ast)
  r['s2'] = clock - t
  r['model'] = Digest::SHA1.hexdigest(dump(doc).gsub(/0x\h+/, ''))
  t = clock
  core = A::Transform::ToCoreModel.transform(doc)
  r['core_t'] = clock - t
  r['core_norm'] = Digest::SHA1.hexdigest(normalized(core))
  r['core'] = Digest::SHA1.hexdigest(dump(core).gsub(/0x\h+/, ''))
  r
rescue StandardError, SystemStackError => e
  r.merge('error' => "#{e.class}: #{e.message[0, 120]}")
end

# Each file runs in a forked child with a hard wall-clock limit: some
# plateau files send the grammar into pathological backtracking (in OLD and
# NEW alike) and native code cannot be interrupted by Timeout.
limit = Float(ENV.fetch('FILE_TIMEOUT', 15))
res = files.to_h do |f|
  rel = f.delete_prefix("#{dir}/")
  text = File.read(f, encoding: 'UTF-8')
  rd, wr = IO.pipe
  pid = fork do
    rd.close
    wr.write(JSON.generate(measure(text)))
    wr.close
    exit!(0)
  end
  wr.close
  deadline = clock + limit
  r = nil
  until r
    if rd.wait_readable([deadline - clock, 0].max)
      data = rd.read
      r = data.empty? ? { 'bytes' => text.bytesize, 'error' => 'child died' } : JSON.parse(data)
    else
      Process.kill('KILL', pid)
      r = { 'bytes' => text.bytesize, 'error' => "timeout #{limit}s" }
    end
  end
  rd.close
  Process.wait(pid)
  warn "#{rel} #{r['error'] || (r['s1'] + r['s2'] + r['core_t']).round(3)}" if ENV['VERBOSE']
  [rel, r]
end
File.write(out, JSON.pretty_generate('ruby' => RUBY_VERSION, 'files' => res))
ok = res.values.count { |v| !v['error'] }
puts "#{files.size} files, #{ok} ok, #{res.values.sum { |v| (v['s1'] || 0) + (v['s2'] || 0) + (v['core_t'] || 0) }.round(2)}s"
