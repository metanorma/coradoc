# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'fileutils'
require 'rspec/core/rake_task'

# Monorepo gems listed in dependency order.
GEMS = %w[coradoc coradoc-adoc coradoc-docx coradoc-markdown coradoc-html].freeze

def gem_dir(name) = name == 'coradoc' ? '.' : name
def task_name(name) = name.tr('-', '_')

def for_each_gem(&) = GEMS.each { |gem| yield gem, task_name(gem), gem_dir(gem) }

# --- Specs ---

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  for_each_gem do |gem_name, task, dir|
    next if gem_name == 'coradoc'
    next unless File.directory?("#{dir}/spec")

    desc "Run specs for #{gem_name}"
    RSpec::Core::RakeTask.new(task) do |t|
      t.pattern = "#{dir}/spec/**/*_spec.rb"
      t.rspec_opts = '--format progress'
    end
  end

  desc 'Run specs for all gems in the monorepo'
  task :all do
    success = true
    for_each_gem do |gem_name, _, dir|
      next unless File.directory?("#{dir}/spec")

      puts "\n=== Running specs for #{gem_name} ==="
      success = false unless system("bundle exec rspec #{dir}/spec --format progress")
    end
    raise 'Some specs failed' unless success
  end
end

task spec_all: 'spec:all'

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
  sh 'irb -Ilib -rcoradoc'
end

require 'bundler/audit/task'
Bundler::Audit::Task.new
