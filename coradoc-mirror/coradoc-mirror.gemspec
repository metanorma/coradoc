# frozen_string_literal: true

require_relative "lib/coradoc/mirror/version"

Gem::Specification.new do |spec|
  spec.name = "coradoc-mirror"
  spec.version = Coradoc::Mirror::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "ProseMirror-compatible JSON document model for Coradoc"
  spec.description = "Transforms Coradoc CoreModel documents into ProseMirror-compatible " \
                     "JSON/YAML suitable for rich frontend rendering with Vue.js, React, " \
                     "or any ProseMirror-based editor."
  spec.homepage = "https://github.com/metanorma/coradoc"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/metanorma/coradoc"
  spec.metadata["changelog_uri"] = "https://github.com/metanorma/coradoc/releases"

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*.rb"]
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "coradoc", "~> 2.0"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "simplecov"
  spec.metadata["rubygems_mfa_required"] = "true"
end
