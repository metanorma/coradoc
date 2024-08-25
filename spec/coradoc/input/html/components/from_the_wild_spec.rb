require "spec_helper"

describe Coradoc::Input::HTML do
  let(:input) do
    File.read("spec/coradoc/input/html/assets/from_the_wild.html")
  end
  let(:document) { Nokogiri::HTML(input) }
  subject { Coradoc::Input::HTML.convert(input) }

  it "should make sense of strong-crazy markup (as seen in the wild)" do
    expect(subject).to include "*. +\n \\*\\*\\* intentcast* : logo design * +\n* *.*"
  end

  it "should not over escape * or _" do
    expect(subject).to include 'link:example.com/foo_bar[image::example.com/foo_bar.png[] I\_AM\_HELPFUL]'
  end
end
