# frozen_string_literal: true

require_relative 'lib/coradoc/plugin/kotoshu/version'

Gem::Specification.new do |spec|
  spec.name = 'coradoc-plugin-kotoshu'
  spec.version = Coradoc::Plugin::Kotoshu::VERSION
  spec.authors = ['Ronald Tse']
  spec.email = ['ronald.tse@ribose.com']

  spec.summary = 'Spell-check AsciiDoc documents using Kotoshu, via the Coradoc CoreModel.'
  spec.description = 'Coradoc plugin that produces a Word-style YAML/JSON spell-check ' \
                     'report for an AsciiDoc document. Walks the Coradoc CoreModel ' \
                     '(the format-neutral document tree), extracts prose from text-bearing ' \
                     'elements, and runs each token through Kotoshu.'

  spec.homepage = 'https://github.com/kotoshu/coradoc-plugin-kotoshu'
  spec.license = 'BSD-2-Clause'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => 'https://github.com/kotoshu/coradoc-plugin-kotoshu',
    'bug_tracker_uri' => 'https://github.com/kotoshu/coradoc-plugin-kotoshu/issues',
    'rubygems_mfa_required' => 'true'
  }

  spec.files = Dir.chdir(__dir__) do
    Dir['lib/**/*.rb', 'exe/*', 'README*', 'LICENSE*', 'CHANGELOG*'].reject { |f| File.directory?(f) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'coradoc', '~> 2.0'
  spec.add_dependency 'coradoc-adoc', '~> 2.0'
  spec.add_dependency 'kotoshu', '~> 0.3'
  spec.add_dependency 'lutaml-model', '~> 0.8'
  spec.add_dependency 'thor', '~> 1.3'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.75'
end
