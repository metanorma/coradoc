require "spec_helper"

describe Coradoc::Input::Html::Converters::Img do
  let(:converter) { described_class.new }

  it "converts image with no attributes" do
    node = node_for("<img src='example.jpg'/>")
    expect(converter.convert(node)).to include "image::example.jpg[]"
  end

  it "annotates missing images in external images mode" do
    expect(Kernel).to receive(:warn).with(/example\.jpg/)

    tmp = Dir.mktmpdir("coradoc-test")
    Coradoc::Input::Html.config.with(
      external_images: true,
      destination: "#{tmp}/index.adoc",
      sourcedir: "#{tmp}/non-existent",
    ) do
      node = node_for("<img src='example.jpg'/>")
      expect(converter.convert(node)).to match %r"// FIXME: Missing image: .*?example.jpg\nimage::"
    end
  ensure
    FileUtils.rm_rf(tmp)
  end

  it "converts image with full set of attributes" do
    node = node_for("<img id='A' alt='Alt Text' src='example.jpg' width='30' height='40'/>")
    expect(converter.convert(node)).to include "[[A]]\nimage::example.jpg[Alt Text,30,40]"
  end

  it "converts image with alt text, no width and height" do
    node = node_for("<img id='A' alt='Alt Text' src='example.jpg'/>")
    expect(converter.convert(node)).to include "[[A]]\nimage::example.jpg[Alt Text]"
  end

  it "converts image with width and height, no alt text" do
    node = node_for("<img id='A' src='example.jpg' width='30' height='40'/>")
    expect(converter.convert(node)).to include "[[A]]\nimage::example.jpg[\"\",30,40]"
  end

  it "converts image with invalid set of attributes" do
    node = node_for("<img src='example.jpg' width='-30' height=''/>")
    expect(converter.convert(node)).to include "image::example.jpg[]"
  end
end
