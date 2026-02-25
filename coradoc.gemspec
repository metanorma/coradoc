# frozen_string_literal: true

require_relative 'lib/coradoc/version'

Gem::Specification.new do |spec|
  spec.name = 'coradoc'
  spec.version = Coradoc::VERSION
  spec.authors = ['Ribose Inc.']
  spec.email = ['open.source@ribose.com']

  spec.summary = 'Canonical Document Model and Transformation Hub'
  spec.description = 'Coradoc provides a hub-and-spoke architecture for ' \
                     'document transformations. The CoreModel serves as the ' \
                     'canonical, format-agnostic representation, enabling ' \
                     'transformations between AsciiDoc, HTML, Markdown, and more.'
  spec.homepage = 'https://github.com/lutaml/coradoc'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Dependencies
  spec.add_dependency 'lutaml-model', '~> 0.7'
  spec.add_dependency 'thor', '>= 1.0'

  # Development dependencies
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
