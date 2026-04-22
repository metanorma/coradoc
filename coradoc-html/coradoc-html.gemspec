# frozen_string_literal: true

require_relative 'lib/coradoc/html/version'

Gem::Specification.new do |spec|
  spec.name = 'coradoc-html'
  spec.version = Coradoc::Html::VERSION
  spec.authors = ['Ribose Inc.']
  spec.email = ['open.source@ribose.com']

  spec.summary = 'HTML input/output converters for Coradoc'
  spec.description = 'Provides HTML to AsciiDoc conversion and AsciiDoc to HTML ' \
                     'rendering with both classic and modern Vue.js SPA themes'
  spec.homepage = 'https://github.com/metanorma/coradoc'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.0.0'

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

  # Dependencies
  spec.add_dependency 'coradoc'
  spec.add_dependency 'coradoc-adoc'
  spec.add_dependency 'marcel', '~> 1.0'
  spec.add_dependency 'nokogiri', '~> 1.0'

  # Development dependencies
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'simplecov'
end
