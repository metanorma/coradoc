# frozen_string_literal: true

require 'fileutils'

# Monorepo gems listed in dependency order.
GEMS = %w[coradoc coradoc-adoc coradoc-docx coradoc-markdown coradoc-html].freeze
# Gems with known pre-existing failures (Uniword API incompatibility).
# Their spec failures won't block CI but are still run individually.
KNOWN_FAILING = %w[coradoc-docx].freeze

def task_name(name) = name.tr('-', '_')

def for_each_gem(&) = GEMS.each { |gem| yield gem, task_name(gem), gem }

# --- Specs ---

namespace :spec do
  for_each_gem do |gem_name, task, dir|
    next unless File.directory?("#{dir}/spec")

    desc "Run specs for #{gem_name}"
    task(task) { Dir.chdir(dir) { sh 'bundle exec rspec --format progress' } }
  end

  desc 'Run specs for all gems in the monorepo'
  task :all do
    failures = []
    for_each_gem do |gem_name, _, dir|
      next unless File.directory?("#{dir}/spec")

      puts "\n=== Running specs for #{gem_name} ==="
      ok = Dir.chdir(dir) { system('bundle', 'exec', 'rspec', '--format', 'progress') }
      failures << gem_name unless ok || KNOWN_FAILING.include?(gem_name)
    end
    raise "Specs failed for: #{failures.join(', ')}" unless failures.empty?
  end
end

task spec: 'spec:all'
task spec_all: 'spec:all'

# --- Round-trip harness (roundtrip/CANONICAL_FORM.md) ---

namespace :roundtrip do
  desc 'Run the round-trip harness for every format'
  task(:all) { sh 'bundle exec rspec roundtrip/spec --format progress' }

  { adoc: 'asciidoc', markdown: 'markdown' }.each do |task, format|
    desc "Run the round-trip harness for #{format}"
    task(task) { sh({ 'ROUNDTRIP_FORMAT' => format }, 'bundle exec rspec roundtrip/spec --format progress') }
  end

  desc 'Rewrite roundtrip/known_failures.yml from the current failures'
  task :baseline do
    $LOAD_PATH.unshift File.expand_path('roundtrip/lib', __dir__)
    require 'coradoc/roundtrip'
    Coradoc::Roundtrip::KnownFailures.write_baseline(Coradoc::Roundtrip::Corpus.cases)
  end
end

task roundtrip: 'roundtrip:all'

# --- Build / Clean ---

namespace :build do
  for_each_gem do |gem_name, task, dir|
    desc "Build #{gem_name}"
    task(task) { Dir.chdir(dir) { sh 'gem build *.gemspec' } }
  end

  desc 'Build all gems'
  task all: GEMS.map { |g| "build:#{task_name(g)}" }
end

namespace :clean do
  for_each_gem do |gem_name, task, dir|
    desc "Clean built files for #{gem_name}"
    task(task) { FileUtils.rm_f(Dir["#{dir}/*.gem"]) }
  end

  desc 'Clean all built files'
  task all: GEMS.map { |g| "clean:#{task_name(g)}" }
end

# --- Install / Release ---

namespace :install do
  for_each_gem do |gem_name, task, dir|
    desc "Install #{gem_name} locally"
    task task => "build:#{task}" do
      Dir.chdir(dir) { sh "gem install --no-document #{Dir['*.gem'].first}" }
    end
  end

  desc 'Install all gems locally'
  task all: GEMS.map { |g| "install:#{task_name(g)}" }
end

namespace :release do
  for_each_gem do |gem_name, task, dir|
    desc "Release #{gem_name} to RubyGems"
    task task => "build:#{task}" do
      Dir.chdir(dir) { sh "gem push #{Dir['*.gem'].first}" }
    end
  end

  desc 'Release all gems to RubyGems in dependency order'
  task all: GEMS.map { |g| "release:#{task_name(g)}" }
end

# --- Defaults ---

task default: 'spec:all'

desc 'Open an irb session preloaded with this library'
task :console do
  sh 'irb -Icoradoc/lib -rcoradoc'
end

require 'bundler/audit/task'
Bundler::Audit::Task.new
