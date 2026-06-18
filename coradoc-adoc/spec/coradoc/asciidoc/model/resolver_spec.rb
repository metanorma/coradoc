require "spec_helper"
require "fileutils"

RSpec.describe Coradoc::AsciiDoc::Model::Resolver do
  describe ".new" do
    it "initializes with default options" do
      resolver = described_class.new
      expect(resolver.include_resolver).to be_nil
      expect(resolver.image_resolver.strategy).to eq(:reference)
      expect(resolver.media_resolver.strategy).to eq(:reference)
      expect(resolver.output_dir).to be_nil
    end

    it "initializes with custom options" do
      resolver = described_class.new(
        includes: true,
        images: :copy,
        media: :embed,
        output_dir: "/tmp/output"
      )
      expect(resolver.include_resolver).to be_a(Coradoc::AsciiDoc::Model::IncludeResolver)
      expect(resolver.image_resolver.strategy).to eq(:copy)
      expect(resolver.media_resolver.strategy).to eq(:embed)
      expect(resolver.output_dir).to eq("/tmp/output")
    end
  end

  describe "resolving models" do
    let(:resolver) { described_class.new }
    let(:base_dir) { "/tmp" }

    it "returns the node if it's not a reference" do
      node = Coradoc::AsciiDoc::Model::Paragraph.new
      expect(resolver.resolve(node, base_dir)).to be(node)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::IncludeResolver do
  let(:resolver) { described_class.new }
  let(:base_dir) { __dir__ }
  
  describe "#resolve" do
    it "returns original node if file not found" do
      node = Coradoc::AsciiDoc::Model::Include.new(path: "missing_file.adoc")
      result = resolver.resolve(node, base_dir)
      expect(result).to eq([node])
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::ImageResolver do
  describe "#resolve" do
    it "returns original node by default for :reference strategy" do
      resolver = described_class.new(strategy: :reference)
      node = Coradoc::AsciiDoc::Model::Image::BlockImage.new(src: "test.png")
      result = resolver.resolve(node, "/tmp")
      expect(result).to eq(node)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::MediaResolver do
  describe "#resolve" do
    it "returns original node by default for :reference strategy" do
      resolver = described_class.new(strategy: :reference)
      node = Coradoc::AsciiDoc::Model::Video.new(src: "test.mp4")
      result = resolver.resolve(node, "/tmp")
      expect(result).to eq(node)
    end
  end
end
