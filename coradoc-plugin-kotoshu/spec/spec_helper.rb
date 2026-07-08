# frozen_string_literal: true

require 'coradoc/plugin/kotoshu'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/.rspec_status'
  config.disable_monkey_patching!
  config.warnings = true
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end

FIXTURES_DIR = File.expand_path('fixtures', __dir__)
WORDS_FIXTURE = File.join(FIXTURES_DIR, 'words.txt')
SAMPLE_ADOC = File.join(FIXTURES_DIR, 'sample.adoc')

def fixture_words_dictionary(language: 'en-US')
  require 'kotoshu'
  Kotoshu::Dictionary::PlainText.new(WORDS_FIXTURE, language_code: language, case_sensitive: false)
end

def build_spellchecker_for_specs(language: 'en-US')
  require 'kotoshu'
  Kotoshu::Spellchecker.new(dictionary: fixture_words_dictionary(language: language))
end

def build_checker_for_specs(language: 'en-US')
  Coradoc::Plugin::Kotoshu::Checker.new(spellchecker: build_spellchecker_for_specs(language: language),
                                        language: language)
end

def read_fixture(name)
  File.read(File.join(FIXTURES_DIR, name))
end
