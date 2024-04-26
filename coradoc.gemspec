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
  spec.required_ruby_version = ">= 2.7.0"

  spec.add_dependency "oscal", "~> 0.1.1"
  spec.add_dependency "parslet"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
end
