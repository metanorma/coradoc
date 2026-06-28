# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'coradoc/asciidoc'

# End-to-end coverage for the image attribute-promotion refactor that crosses
# coradoc-adoc (parsing) and coradoc-mirror (rendering) gems.
# Verifies the three symptoms reported in BUG-image-named-attrs-as-json-arrays.md:
#   1. Named attrs (width, height) are scalar strings, not JSON-array strings.
#   2. inline: true is set on inline images, false on block images.
#   3. The 2nd positional on inline images is interpreted as role, not caption;
#      inline images are no longer wrapped in <figure>.
RSpec.describe 'Image typed attributes (BUG-image-named-attrs)' do
  def mirror_node(adoc, partition_structural: true)
    core = Coradoc.parse(adoc, format: :asciidoc)
    Coradoc::Mirror::Transformer.new.from_core_model(
      core, partition_structural: partition_structural
    )
  end

  def mirror_json(adoc, **opts)
    JSON.parse(mirror_node(adoc, **opts).to_json)
  end

  def first_image_attrs(json)
    json.dig('content', 0, 'content', 0, 'content', 0, 'attrs') ||
      json.dig('content', 0, 'content', 0, 'attrs')
  end

  describe 'inline image with named width/height' do
    let(:adoc) { "image:foo.png[Alt text, width=640, height=480]\n" }
    let(:attrs) { first_image_attrs(mirror_json(adoc)) }

    it 'emits width and height as scalar strings, not JSON arrays' do
      expect(attrs['width']).to eq('640')
      expect(attrs['height']).to eq('480')
    end

    it 'sets inline: true' do
      expect(attrs['inline']).to be true
    end

    it 'does not wrap inline images in figure nodes' do
      content = mirror_json(adoc).dig('content', 0, 'content', 0, 'content')
      types = Array(content).map { |n| n['type'] }
      expect(types).not_to include('figure')
      expect(types).to include('image')
    end
  end

  describe 'inline image with 2-pos role' do
    let(:adoc) { "Inline: image:foo.png[Alt, SomeRole] here\n" }
    let(:image_node) do
      content = mirror_json(adoc).dig('content', 0, 'content', 0, 'content')
      content.find { |n| n['type'] == 'image' }
    end

    it 'records the 2nd positional as role, not caption' do
      expect(image_node['attrs']['role']).to eq('SomeRole')
      expect(image_node['attrs']['caption']).to be_nil
    end

    it 'is not wrapped in figure' do
      content = mirror_json(adoc).dig('content', 0, 'content', 0, 'content')
      expect(Array(content).map { |n| n['type'] }).not_to include('figure')
    end
  end

  describe 'block image with .Caption' do
    let(:adoc) { ".My Caption\nimage::block.png[Alt]\n" }
    let(:json) { mirror_json(adoc) }

    it 'wraps the image in a figure node' do
      figure = json.dig('content', 0, 'content', 0)
      expect(figure['type']).to eq('figure')
      types = Array(figure['content']).map { |n| n['type'] }
      expect(types).to include('image')
      expect(types).to include('caption')
    end

    it 'records the block title as the figure caption' do
      figure = json.dig('content', 0, 'content', 0)
      expect(figure['type']).to eq('figure')
      expect(figure['attrs']['title']).to eq('My Caption')
    end

    it 'marks the inner image as inline=false' do
      figure = json.dig('content', 0, 'content', 0)
      image = figure['content'].find { |n| n['type'] == 'image' }
      expect(image['attrs']['inline']).to be false
    end
  end

  describe 'block image with named attrs' do
    let(:adoc) { "image::b.png[Alt, width=800, height=600, role=figure]\n" }
    let(:attrs) { first_image_attrs(mirror_json(adoc)) }

    it 'promotes named width/height/role' do
      expect(attrs['width']).to eq('800')
      expect(attrs['height']).to eq('600')
      expect(attrs['role']).to eq('figure')
    end
  end
end
