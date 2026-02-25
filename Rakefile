# frozen_string_literal: true

require 'bundler/gem_tasks'

ENV['CODECLIMATE_REPO_TOKEN'] = File.read('.codeclimate').strip if File.exist?('.codeclimate')

require 'rspec/core/rake_task'

# Monorepo gems
GEMS = %w[coradoc coradoc-adoc coradoc-html coradoc-markdown coradoc-docx].freeze

# Main gem spec task
RSpec::Core::RakeTask.new(:spec)

# Individual gem spec tasks
namespace :spec do
  GEMS.each do |gem_name|
    next if gem_name == 'coradoc'

    gem_dir = File.dirname(__FILE__) + "/#{gem_name}"

    next unless File.directory?("#{gem_dir}/spec")

    desc "Run specs for #{gem_name}"
    RSpec::Core::RakeTask.new(gem_name.tr('-', '_').to_sym) do |t|
      t.pattern = "#{gem_dir}/spec/**/*_spec.rb"
      t.rspec_opts = '--format progress'
    end
  end
end

# Task to run all gem specs
desc 'Run specs for all gems in the monorepo'
task :spec_all do
  success = true

  GEMS.each do |gem_name|
    gem_dir = File.dirname(__FILE__) + "/#{gem_name}"
    next unless File.directory?("#{gem_dir}/spec")

    puts "\n=== Running specs for #{gem_name} ==="
    result = system("bundle exec rspec #{gem_dir}/spec --format progress")
    success = false unless result
  end

  raise 'Some specs failed' unless success
end

task default: :spec_all

desc 'Open an irb session preloaded with this library'
task :console do
  sh 'irb -Ilib -rcoradoc'
end

require 'bundler/audit/task'
Bundler::Audit::Task.new
