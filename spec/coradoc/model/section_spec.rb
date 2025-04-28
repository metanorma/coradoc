require "spec_helper"

RSpec.describe Coradoc::Model::Section do
  let(:title) { instance_double(Coradoc::Model::Title) }
  let(:paragraph) { instance_double(Coradoc::Model::Paragraph) }
  let(:subsection) { instance_double(described_class) }

  describe ".initialize" do
    it "initializes with basic attributes" do
      section = described_class.new(
        id: "section-1",
        content: "Section content",
        title: title
      )

      expect(section.id).to eq("section-1")
      expect(section.content).to eq("Section content")
      expect(section.title).to eq(title)
      expect(section.attrs).to eq([])
      expect(section.contents).to eq([])
      expect(section.sections).to eq([])
    end

    it "initializes with empty collections by default" do
      section = described_class.new

      expect(section.attrs).to eq([])
      expect(section.contents).to eq([])
      expect(section.sections).to eq([])
    end

    it "accepts collections" do
      named_attr = instance_double(Coradoc::Model::NamedAttribute)

      section = described_class.new(
        title: title,
        attrs: [named_attr],
        contents: [paragraph],
        sections: [subsection]
      )

      expect(section.attrs).to eq([named_attr])
      expect(section.contents).to eq([paragraph])
      expect(section.sections).to eq([subsection])
    end
  end

  describe "nested structure" do
    it "supports nested sections" do
      subsection1 = described_class.new(id: "sub1", title: title)
      subsection2 = described_class.new(id: "sub2", title: title)

      section = described_class.new(
        id: "main",
        title: title,
        sections: [subsection1, subsection2]
      )

      expect(section.sections.map(&:id)).to eq(["sub1", "sub2"])
    end

    it "supports mixed content" do
      section = described_class.new(
        title: title,
        contents: [paragraph],
        sections: [subsection]
      )

      expect(section.contents).to eq([paragraph])
      expect(section.sections).to eq([subsection])
    end
  end

  describe "inheritance and includes" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end

    it "includes Anchorable module" do
      expect(described_class.included_modules).to include(Coradoc::Model::Anchorable)
    end
  end

  describe "attribute types" do
    it "uses correct types for collections" do
      section = described_class.new

      expect(section.attrs).to be_a(Array)
      expect(section.contents).to be_a(Array)
      expect(section.sections).to be_a(Array)
    end

    it "validates attribute types" do
      expect { described_class.new(title: "Invalid Title") }
        .to raise_error(TypeError)
    end
  end



  describe "attribute collections" do
    let(:section) { described_class.new(title: title) }

    it "allows adding named attributes" do
      named_attr = instance_double(Coradoc::Model::NamedAttribute)
      section.attrs << named_attr
      expect(section.attrs).to include(named_attr)
    end

    it "allows adding paragraphs" do
      section.contents << paragraph
      expect(section.contents).to include(paragraph)
    end

    it "allows adding subsections" do
      section.sections << subsection
      expect(section.sections).to include(subsection)
    end
  end
end
