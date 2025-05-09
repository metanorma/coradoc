require "spec_helper"

describe Coradoc::Input::Html do
  subject { Coradoc::Input::Html.convert(input) }

  let(:input) do
    File.read("spec/coradoc/input/html/assets/from_the_wild.html")
  end
  let(:document) { Nokogiri::HTML(input) }

  it "makes sense of strong-crazy markup (as seen in the wild)" do
    is_expected.to include "*. +\n \\*\\*\\* intentcast* : logo design * +\n* *.*"
  end

  it "does not over escape * or _" do
    is_expected.to include 'link:example.com/foo_bar[image::example.com/foo_bar.png[] I\_AM\_HELPFUL]'
  end
end
