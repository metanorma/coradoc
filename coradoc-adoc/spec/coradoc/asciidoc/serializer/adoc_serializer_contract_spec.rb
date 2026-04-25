# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Serializer::AdocSerializer do
  describe 'error-handling contract' do
    describe '.serialize' do
      it 'raises ArgumentError for unknown element types' do
        expect { described_class.serialize(Object.new) }.to raise_error(
          ArgumentError,
          /Unknown element type for AsciiDoc serialization: Object/
        )
      end

      it 'raises ArgumentError for Lutaml::Model objects without to_adoc' do
        lutaml_model = Class.new(Lutaml::Model::Serializable).new

        expect { described_class.serialize(lutaml_model) }.to raise_error(
          ArgumentError,
          /Cannot serialize.*to AsciiDoc/
        )
      end

      it 'serializes nil as empty string' do
        expect(described_class.serialize(nil)).to eq('')
      end

      it 'serializes strings directly' do
        expect(described_class.serialize('hello')).to eq('hello')
      end

      it 'serializes arrays' do
        expect(described_class.serialize(['a', 'b'])).to eq('ab')
      end
    end
  end
end
