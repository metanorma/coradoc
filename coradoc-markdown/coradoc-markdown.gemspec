# frozen_string_literal: true

require_relative 'lib/coradoc/markdown/version'

Gem::Specification.new do |spec|
  spec.name = 'coradoc-markdown'
  spec.version = Coradoc::Markdown::VERSION
  spec.authors = ['Ribose Inc.']
  spec.email = ['open.source@ribose.com']

  spec.summary = 'Markdown document model, parser, and serializer for Coradoc'
  spec.description = 'Provides Markdown parsing and serialization capabilities for Coradoc. ' \
                     'Includes the Markdown Document Model, a CommonMark-compliant Parslet-based ' \
                     'parser, and round-trip capable serializer.'
  spec.homepage = 'https://github.com/metanorma/coradoc'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/metanorma/coradoc'
  spec.metadata['changelog_uri'] = 'https://github.com/metanorma/coradoc/releases'

  # Include all lib/ files
  spec.files = Dir.chdir(__dir__) do
    Dir['lib/**/*.rb'] + ['LICENSE.txt']
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Core dependencies
  spec.add_dependency 'coradoc'
  spec.add_dependency 'lutaml-model'
  spec.add_dependency 'parslet'

  # Development dependencies
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'simplecov'
end
