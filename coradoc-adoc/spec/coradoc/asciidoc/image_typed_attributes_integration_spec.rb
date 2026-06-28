# frozen_string_literal: true

require 'spec_helper'

# End-to-end AsciiDoc coverage for the image attribute-promotion refactor.
# Cross-gem mirror-JSON scenarios live in coradoc-mirror/spec/coradoc/mirror/
# image_typed_attributes_spec.rb.
RSpec.describe 'Image typed attributes round-trip' do
  describe 'adoc → CoreModel → adoc' do
    it 'preserves inline image named attrs as scalars', :aggregate_failures do
      adoc = "image:foo.png[Alt, MyRole, width=640, height=480, link=https://example.org]\n"
      serialized = Coradoc.serialize(Coradoc.parse(adoc, format: :asciidoc), to: :asciidoc)
      expect(serialized).to include('image:foo.png')
      expect(serialized).to include('width=640')
      expect(serialized).to include('height=480')
      expect(serialized).to include('link=https://example.org')
      expect(serialized).to include('MyRole')
      expect(serialized).not_to include('["640"]')
    end

    it 'preserves block image named attrs', :aggregate_failures do
      adoc = "image::b.png[Alt, width=800, height=600, role=figure]\n"
      serialized = Coradoc.serialize(Coradoc.parse(adoc, format: :asciidoc), to: :asciidoc)
      expect(serialized).to include('image::b.png')
      expect(serialized).to include('width=800')
      expect(serialized).to include('height=600')
      expect(serialized).to include('role=figure')
    end

    it 'preserves block image caption via block-title', :aggregate_failures do
      adoc = ".My Caption\nimage::block.png[Alt]\n"
      serialized = Coradoc.serialize(Coradoc.parse(adoc, format: :asciidoc), to: :asciidoc)
      expect(serialized).to include('.My Caption')
      expect(serialized).to include('image::block.png')
    end
  end

  describe 'AsciiDoc-only residual attrs survive adoc→adoc parse-then-serialize' do
    let(:adoc_model) { Coradoc::AsciiDoc.parse("image:foo.png[Alt, scaledwidth=50%]\n") }
    let(:image) { adoc_model.sections.first.content.first.content.first }

    it 'promotes the inline image model' do
      expect(image).to be_a(Coradoc::AsciiDoc::Model::Image::InlineImage)
    end

    it 'captures alt as a typed field' do
      expect(image.alt).to eq('Alt')
    end

    it 'preserves scaledwidth in the residual attributes' do
      expect(image.attributes['scaledwidth']).to eq('50%')
    end

    it 'serializes scaledwidth back to adoc' do
      serialized = Coradoc::AsciiDoc::Serializer::AdocSerializer.serialize(adoc_model)
      expect(serialized).to include('scaledwidth=50%')
    end
  end
end
