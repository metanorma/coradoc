# frozen_string_literal: true

RSpec.describe Coradoc::Model::Image::Core do
  describe ".initialize" do
    it "initializes and exposes image attributes" do
      id = "image-1"
      title = "Sample Image"
      src = "path/to/image.jpg"
      attributes = Coradoc::Model::AttributeList.new
      line_break = "\n"

      image = described_class.new(
        id: id,
        title: title,
        src: src,
        attributes: attributes,
        line_break: line_break,
      )

      expect(image.id).to eq(id)
      expect(image.title).to eq(title)
      expect(image.src).to eq(src)
      expect(image.attributes).to eq(attributes)
      expect(image.line_break).to eq(line_break)
    end

    it "uses default values when not provided" do
      image = described_class.new

      expect(image.attributes).to be_a(Coradoc::Model::AttributeList)
      expect(image.line_break).to eq("")
    end
  end

  describe "#to_asciidoc" do
    it "generates correct asciidoc output with all attributes" do
      image = described_class.new(
        id: "img-1",
        title: "Test Image",
        src: "test.png",
        line_break: "\n",
      )

      expected_output = "[[img-1]]\n.Test Image\nimage#{image.colons}test.png[]\n"
      expect(image.to_asciidoc).to eq(expected_output)
    end

    it "includes annotate_missing message when specified" do
      image = described_class.new(
        src: "test.png",
        annotate_missing: "missing.jpg",
        line_break: "\n",
      )

      expected_output = "// FIXME: Missing image: missing.jpg\nimage#{image.colons}test.png[]\n"
      expect(image.to_asciidoc).to eq(expected_output)
    end

    it "handles empty title" do
      image = described_class.new(
        src: "test.png",
        title: "",
        line_break: "\n",
      )

      expected_output = "image#{image.colons}test.png[]\n"
      expect(image.to_asciidoc).to eq(expected_output)
    end
  end
end
