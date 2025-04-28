# frozen_string_literal: true

RSpec.describe Coradoc::Model::Video do
  describe ".initialize" do
    it "initializes with required attributes" do
      video = described_class.new(
        id: "video-1",
        title: "Sample Video",
        src: "video.mp4"
      )

      expect(video.id).to eq("video-1")
      expect(video.title).to eq("Sample Video")
      expect(video.src).to eq("video.mp4")
      expect(video.attributes).to be_a(Coradoc::Model::AttributeList)
    end

    it "uses default values when not provided" do
      video = described_class.new

      expect(video.src).to eq("")
      expect(video.attributes).to be_a(Coradoc::Model::AttributeList)
      expect(video.attributes).to be_empty
    end
  end

  describe "#to_asciidoc" do
    let(:attributes) { Coradoc::Model::AttributeList.new }

    before do
      allow(attributes).to receive(:to_asciidoc).and_return("[width=640]")
    end

    it "generates asciidoc with all attributes" do
      video = described_class.new(
        id: "video-1",
        title: "Sample Video",
        src: "video.mp4",
        attributes: attributes
      )

      expected_output = ".Sample Video\nvideo::video.mp4[width=640]"
      expect(video.to_asciidoc).to eq(expected_output)
    end

    it "handles empty title" do
      video = described_class.new(
        src: "video.mp4",
        attributes: attributes
      )

      expected_output = "video::video.mp4[width=640]"
      expect(video.to_asciidoc).to eq(expected_output)
    end

    it "includes anchor when provided" do
      anchor = instance_double(Coradoc::Model::Inline::Anchor,
        to_asciidoc: "[[video-anchor]]"
      )

      video = described_class.new(
        id: "video-1",
        title: "Sample Video",
        src: "video.mp4",
        attributes: attributes
      )

      allow(video).to receive(:anchor).and_return(anchor)

      expected_output = "[[video-anchor]]\n.Sample Video\nvideo::video.mp4[width=640]"
      expect(video.to_asciidoc).to eq(expected_output)
    end

    it "handles no attributes" do
      video = described_class.new(
        title: "Sample Video",
        src: "video.mp4"
      )

      expected_output = ".Sample Video\nvideo::video.mp4[]"
      expect(video.to_asciidoc).to eq(expected_output)
    end
  end
end
