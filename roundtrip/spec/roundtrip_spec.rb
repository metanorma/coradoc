# frozen_string_literal: true

require_relative 'spec_helper'

# One example per corpus case. Run a single format with
#   ROUNDTRIP_FORMAT=markdown bundle exec rspec roundtrip/spec
#
# A case listed in known_failures.yml is an expected failure: it must keep
# failing (RSpec fails a pending example that passes), so fixing a bug
# forces its entry out of the list.
RSpec.describe 'CoreModel round trip' do
  let(:checker) { Coradoc::Roundtrip::Checker.new }
  let(:known) { Coradoc::Roundtrip::KnownFailures.new }

  wanted = ENV['ROUNDTRIP_FORMAT']&.to_sym

  Coradoc::Roundtrip::FORMATS.each do |format|
    next if wanted && wanted != format

    describe format.to_s do
      Coradoc::Roundtrip::Corpus.cases(format: format).each do |kase|
        it kase.id do
          pending(known.reason(kase.id)) if known.include?(kase.id)

          failure = checker.call(kase)

          expect(failure).to be_nil, failure&.to_s
        end
      end
    end
  end

  it 'lists only cases that exist in the corpus' do
    ids = Coradoc::Roundtrip::Corpus.cases.map(&:id)

    expect(known.ids - ids).to eq([])
  end
end
