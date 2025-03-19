# frozen_string_literal: true

require_relative "lib/coradoc/version"

Gem::Specification.new do |spec|
  spec.name = "coradoc"
  spec.version = Coradoc::VERSION
  spec.authors = ["Ribose Inc.", "Abu Nashir"]
  spec.email = ["open.source@ribose.com", "abunashir@gmail.com"]

  spec.license = "MIT"
  spec.homepage = "https://www.metanorma.org"
  spec.summary = "AsciiDoc parser for metanorma"
  spec.description = "Experimental AsciiDoc parser for metanorma"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/metanorma/coradoc"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.1.0"

  spec.add_dependency "base64"
  spec.add_dependency "lutaml-model"
  spec.add_dependency "marcel", "~> 1.0.0"
  spec.add_dependency "nokogiri", "~> 1.13"
  spec.add_dependency "oscal", "~> 0.1.1"
  spec.add_dependency "parslet"
  spec.add_dependency "plurimath"
  spec.add_dependency "thor", ">= 1.3.0"
  spec.add_dependency "unitsml"
  spec.add_dependency "word-to-markdown"
end
