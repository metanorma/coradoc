# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'tempfile'

RSpec.describe Coradoc::Plugin::Kotoshu::Cli, '# integration' do
  let(:exe) { File.expand_path('../../exe/coradoc-kotoshu', __dir__) }
  let(:dict) { WORDS_FIXTURE }

  def run_cli(*args)
    env = { 'KOTOSHU_NO_ONNX' => '1', 'KOTOSHU_NO_NETWORK' => '1' }
    stdout, status = Open3.capture2(env, exe, *args)
    [stdout, status]
  end

  it 'prints the version' do
    out, status = run_cli('version')
    expect(status.success?).to be true
    expect(out).to match(/coradoc-plugin-kotoshu \d+\.\d+\.\d+/)
  end

  it 'checks an AsciiDoc file with a custom dictionary' do
    Tempfile.create(['sample', '.adoc']) do |adoc|
      adoc.write(<<~ADOC)
        = Title

        This paragraf has a helo.
      ADOC
      adoc.close

      out, status = run_cli('check', adoc.path, '--spellchecker', dict, '--format', 'json')
      expect(status.success?).to be true
      parsed = JSON.parse(out)
      expect(parsed['errors'].map { |e| e['word'] }).to include('paragraf')
      expect(parsed['errors'].map { |e| e['word'] }).to include('helo')
    end
  end

  it 'writes a YAML report to --output' do
    Tempfile.create(['sample', '.adoc']) do |adoc|
      Tempfile.create(['report', '.yaml']) do |report_path|
        adoc.write(<<~ADOC)
          = Title

          Misspelled paragraf here.
        ADOC
        adoc.close

        _out, status = run_cli('check', adoc.path, '--spellchecker', dict,
                               '--format', 'yaml', '--output', report_path.path)
        expect(status.success?).to be true
        content = File.read(report_path.path)
        expect(content).to match(/paragraf/)
      end
    end
  end

  it 'errors when file is missing' do
    _out, status = run_cli('check', '/no/such/file.adoc')
    expect(status.success?).to be false
  end

  it 'errors for an invalid format' do
    Tempfile.create(['sample', '.adoc']) do |adoc|
      adoc.write("hello\n")
      adoc.close
      _out, status = run_cli('check', adoc.path, '--spellchecker', dict, '--format', 'bogus')
      expect(status.success?).to be false
    end
  end
end
