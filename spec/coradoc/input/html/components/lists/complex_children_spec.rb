require "spec_helper"

describe Coradoc::Element::ListItem do
  def input(input, should_convert_to:)
    Coradoc::Input::Html.convert(input).should be == should_convert_to
  end

  it "works with simple blocks" do
    input "<ul><li>abc</li></ul>", should_convert_to: "* abc\n"
  end

  it "does not expand inline elements" do
    input "<ul><li>abc<b>def</b>ghi</li></ul>",
          should_convert_to: "* abc**def**ghi\n"
    input "<ul><li>abc<a href='c'>ddd</a>ghi</li></ul>",
          should_convert_to: "* abc link:c[ddd]ghi\n"
  end

  it "strips spaces only where it makes sense" do
    input "<ul><li> test <b>test</b> test</li> </ul>",
          should_convert_to: "* test *test* test\n"
  end

  it "expands non-inline elements like tables" do
    input "<ul><li>xx<table><tr><td>test</td></tr></table></li></ul>",
          should_convert_to: <<~ADOC
            * xx
            +
            [cols=1]
            |===
            | test

            |===
          ADOC
  end

  it "prefixes non-inline elements with {empty}" do
    input "<ul><li><pre>abc</pre></li></ul>",
          should_convert_to: <<~ADOC
            * {empty}
            +
            ....
            abc
            ....
          ADOC
  end

  it "does not prefix inline elements with {empty}" do
    input "<ul><li><b>abc</b></li></ul>",
          should_convert_to: <<~ADOC
            * *abc*
          ADOC
  end

  it "replaces empty elements with {empty}" do
    input "<ul><li></li><li></li><li></li></ul>",
          should_convert_to: <<~ADOC
            * {empty}
            * {empty}
            * {empty}
          ADOC
  end

  it "handles linebreaks like paragraphs" do
    input "<ul><li>test<br>test<br>test</li></ul>",
          should_convert_to: <<~ADOC
            * test
            +
            test
            +
            test
          ADOC

    input "<ul><li><p>test<p>test<p>test</li></ul>",
          should_convert_to: <<~ADOC
            * {empty}
            +
            test
            +
            test
            +
            test
          ADOC
  end
end
