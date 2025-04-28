require "spec_helper"

RSpec.describe Coradoc::Model::Audio do
  describe ".initialize" do
    it "initializes with basic attributes" do
      audio = described_class.new(
        id: "audio-1",
        title: "Sample Audio",
        src: "audio.mp3"
      )

      expect(audio.id).to eq("audio-1")
      expect(audio.title).to eq("Sample Audio")
      expect(audio.src).to eq("audio.mp3")
      expect(audio.attributes).to eq([])
    end

    it "uses default values when not provided" do
      audio = described_class.new

      expect(audio.src).to eq("")
      expect(audio.attributes).to eq([])
    end
  end

  describe "#to_asciidoc" do
    let(:title) { "Sample Audio" }
    let(:src) { "audio.mp3" }

    it "generates basic audio markup" do
      audio = described_class.new(
        title: title,
        src: src
      )

      expected_output = ".Sample Audio\naudio::audio.mp3[]"
      expect(audio.to_asciidoc).to eq(expected_output)
    end

    it "includes attributes when present" do
      audio = described_class.new(
        title: title,
        src: src,
        attributes: ["start=30", "end=60"]
      )

      expected_output = ".Sample Audio\naudio::audio.mp3[start=30,end=60]"
      expect(audio.to_asciidoc).to eq(expected_output)
    end

    it "includes anchor when present" do
      anchor = instance_double(Coradoc::Model::Inline::Anchor,
        to_asciidoc: "[[audio-1]]"
      )

      audio = described_class.new(
        title: title,
        src: src
      )
      allow(audio).to receive(:anchor).and_return(anchor)

      expected_output = "[[audio-1]]\n.Sample Audio\naudio::audio.mp3[]"
      expect(audio.to_asciidoc).to eq(expected_output)
    end

    it "handles missing title" do
      audio = described_class.new(src: src)
      expect(audio.to_asciidoc).to eq("audio::audio.mp3[]")
    end

    it "handles empty src" do
      audio = described_class.new(title: title)
      expect(audio.to_asciidoc).to eq(".Sample Audio\naudio::[]")
    end

    it "combines all elements" do
      anchor = instance_double(Coradoc::Model::Inline::Anchor,
        to_asciidoc: "[[audio-1]]"
      )

      audio = described_class.new(
        title: title,
        src: src,
        attributes: ["start=30", "end=60"]
      )
      allow(audio).to receive(:anchor).and_return(anchor)

      expected_output = "[[audio-1]]\n.Sample Audio\naudio::audio.mp3[start=30,end=60]"
      expect(audio.to_asciidoc).to eq(expected_output)
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end

    it "includes Anchorable module" do
      expect(described_class.included_modules).to include(Coradoc::Model::Anchorable)
    end
  end
end
