require "spec_helper"

describe Coradoc::Input::Html do
  let(:document) { Nokogiri::HTML(input) }
  let(:adoc) { described_class.convert(document) }

  shared_examples "test" do |name, test, expected_result|
    context name do
      let(:input) { test }
      let(:subject) { adoc }

      it "is fixed" do
        expect(subject.chomp.chomp).to be == expected_result
      end
    end
  end

  def self.t(name = nil, test, expected_result)
    name ||= expected_result
    include_examples "test", name, test, expected_result
  end

  # https://github.com/metanorma/reverse_adoc/issues/93
  t "issue with disappearing spaces inside i elements",
    "test<i> </i>test<i>test</i>", "test test__test__"

  t "issue with disappearing spaces inside em elements",
    "test<em> </em>test<em>test</em>", "test test__test__"

  t "issue with disappearing spaces inside b elements",
    "test<b> </b>test<b>test</b>", "test test**test**"

  t "issue with disappearing spaces inside strong elements",
    "test<strong> </strong>test<strong>test</strong>", "test test**test**"

  t "issue with disappearing spaces inside code elements",
    "test<code> </code>test<code>test</code>", "test test``test``"

  t "issue with disappearing spaces inside mark elements",
    "test<mark> </mark>test<mark>test</mark>", "test test##test##"

  # https://github.com/metanorma/coradoc/issues/43
  t "<code>standalone</code> monospace", "`standalone` monospace"
  t "<code>mono</code>space", "``mono``space"
  t "<b>bold</b> itself", "*bold* itself"
  t "attached<b>bold</b>here", "attached**bold**here"
  t "<i>italics</i> itself", "_italics_ itself"
  t "attached<i>italics</i>here", "attached__italics__here"
  t "<mark>highlight</mark> itself", "#highlight# itself"
  t "attached<mark>highlight</mark>here", "attached##highlight##here"

  # https://github.com/metanorma/coradoc/issues/96
  t "<ul><li>test</li><ul><li>test</li></ul></ul>", "* test\n\n** test"
  t "<ol><li>test</li><ol><li>test</li></ol></ol>", ". test\n\n.. test"
  t "<ul><li>test</li><ol><li>test</li></ol></ul>", "* test\n\n.. test"
end
