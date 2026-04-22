# frozen_string_literal: true

require_relative 'lib/coradoc/docx/version'

Gem::Specification.new do |spec|
  spec.name = 'coradoc-docx'
  spec.version = Coradoc::Docx::VERSION
  spec.authors = ['Ribose Inc.']
  spec.email = ['open.source@ribose.com']

  spec.summary = 'DOCX (OOXML) format support for Coradoc'
  spec.description = 'Provides OOXML (DOCX) to CoreModel transformation ' \
                     'for the Coradoc document transformation hub. ' \
                     'Uses Uniword to read DOCX files and transforms ' \
                     'the OOXML model tree to Coradoc::CoreModel.'
  spec.homepage = 'https://github.com/lutaml/coradoc'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'coradoc', '~> 2.0'
  spec.add_dependency 'lutaml-model', '~> 0.8.0'
  spec.add_dependency 'uniword'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
