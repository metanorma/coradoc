# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake"

group :doc do
  gem "redcarpet"
end

group :development do
  gem "irb"
  gem "pry"
end

group :test do
  gem "bundler-audit"
  gem "codeclimate-test-reporter"
  gem "rspec"
  gem "rspec-its"
  gem "simplecov"
end

group :rubocop do
  gem "rubocop", "~> 1.75.2", require: false
  gem "rubocop-packaging"
  gem "rubocop-performance"
  gem "rubocop-rake"
  gem "rubocop-rspec"
end

# gem "parallel_tests"
# gem "stackprof"

# For Ruby 3.5
gem "logger"
gem "reline"

# Local development gemfile
begin
  local_gemfile = File.expand_path("Gemfile.local", __dir__)
  if File.exist?(local_gemfile)
    warn "Gemfile: Loading local Gemfile at: #{local_gemfile}"
    eval_gemfile(local_gemfile)
  end
rescue StandardError => e
  warn "Error loading local Gemfile: #{e.message}"
end

