# frozen_string_literal: true

require_relative 'lib/coradoc/asciidoc/version'

Gem::Specification.new do |spec|
  spec.name = 'coradoc-adoc'
  spec.version = Coradoc::AsciiDoc::VERSION
  spec.authors = ['Ribose Inc.']
  spec.email = ['open.source@ribose.com']

  spec.summary = 'AsciiDoc support for Coradoc'
  spec.description = 'AsciiDoc Document Model, Parser, and Serializer for the ' \
                     'Coradoc document transformation framework. Provides ' \
                     'bidirectional transformation between AsciiDoc and CoreModel.'
  spec.homepage = 'https://github.com/lutaml/coradoc'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f == __FILE__ || f.match(%r{\A(?:test|spec|features)/})
    end
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'coradoc'
  spec.add_dependency 'lutaml-model', '~> 0.7'
  spec.add_dependency 'parslet'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
