require "spec_helper"

describe Coradoc::Input::Html::Converters::Figure do
  let(:converter) { described_class.new }

  it "converts figure" do
    node = node_for("<figure id='A'><img src='example.jpg'/><figcaption>Figure <i>caption</i></figcaption></figure>")
    expect(converter.convert(node)).to include "[[A]]\n.Figure _caption_\n====\nimage::example.jpg[]\n====\n"
  end
end
