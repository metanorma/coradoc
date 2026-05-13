# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Serializer do
  describe 'error-handling contract' do
    describe 'top-level dispatch' do
      it 'raises ArgumentError for unknown element types' do
        unknown = Object.new

        expect { described_class.serialize(unknown) }.to raise_error(
          ArgumentError,
          /Unknown element type for serialization: Object/
        )
      end
    end

    describe 'inline content dispatch' do
      it 'raises ArgumentError for unknown inline content' do
        para = Coradoc::Markdown::Paragraph.new(
          children: [Object.new]
        )

        expect { described_class.serialize(para) }.to raise_error(
          ArgumentError,
          /Cannot serialize inline content of type Object/
        )
      end
    end
  end
end
