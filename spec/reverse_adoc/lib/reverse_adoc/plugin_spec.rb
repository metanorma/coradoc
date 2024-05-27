require "spec_helper"

describe Coradoc::ReverseAdoc::Plugin do
  let(:input)    { "<html><body><div><table><tr><td>hello</td></tr></table></div></body></html>" }
  let(:document) { Nokogiri::HTML(input) }
  subject { Coradoc::ReverseAdoc.convert(input, plugins: plugins) }
  let(:plugins)  { [plugin] }

  context "#preprocess_html_tree" do
    let(:plugin) do
      c = code
      described_class.new do
        define_method(:preprocess_html_tree) { instance_exec(&c) }
      end
    end

    context "#html_tree_remove_by_css" do
      let(:code) do -> {
        html_tree_remove_by_css("table")
      } end

      it { should_not include "hello" }
    end

    context "#html_tree_change_tag_name_by_css" do
      let(:code) do -> {
        html_tree_change_tag_name_by_css("table", "ul")
        html_tree_change_tag_name_by_css("tr", "li")
        html_tree_change_tag_name_by_css("td", "span")
      } end

      it { should include "* hello" }
    end

    context "#html_tree_change_properties_by_css" do
      let(:code) do -> {
        html_tree_change_properties_by_css("td", valign: "bottom")
      } end

      it { should include ".>|" }
    end

    context "#html_tree_replace_with_children_by_css" do
      let(:code) do -> {
        html_tree_replace_with_children_by_css("table, tr, td")
      } end

      it { should include "hello" }
      it { should_not include "|===" }
    end

    context "#html_tree_preview" do
      let(:code) do -> {
        html_tree_preview
      } end

      let(:fake_tempfile) { instance_double(Tempfile, path: '/fake/path/to/tempfile.html') }
      let(:plugin_instance) { plugin.new }

      it "creates a temporary HTML file and opens it with chromium-browser" do
        allow(Tempfile).to receive(:open).and_yield(fake_tempfile)
        allow(fake_tempfile).to receive(:<<)
        allow(fake_tempfile).to receive(:close)
        allow(fake_tempfile).to receive(:unlink)
        allow(plugin).to receive(:new).and_return(plugin_instance)
        allow(plugin_instance).to receive(:system).and_return(true)

        subject

        expect(Tempfile).to have_received(:open).with(%w"coradoc .html")
        expect(fake_tempfile).to have_received(:<<).with(input)
        expect(plugin_instance).to have_received(:system).with("chromium-browser", "--no-sandbox", fake_tempfile.path)
      end
    end

    context "#html_tree_add_hook_pre_by_css" do
      let(:code) do -> {
        html_tree_add_hook_pre_by_css "div" do |node, _|
          node.content.reverse
        end
      } end

      it { should_not include "hello" }
      it { should include "olleh" }
    end

    context "#html_tree_process_to_adoc" do
      let(:code) do -> {
        html_tree_add_hook_pre_by_css "div" do |node, _|
          td = node.at_css('td')
          td.children.first.content = td.text.reverse
          html_tree_process_to_adoc(node)
        end
      } end

      it { should_not include "hello" }
      it { should include "olleh" }
      it { should include "|===" }
    end

    context "#html_tree_process_to_coradoc" do
      let(:code) do -> {
        html_tree_add_hook_pre_by_css "td" do |node, _|
          node.children.first.content = node.text.reverse
          coradoc = html_tree_process_to_coradoc(node)
          coradoc.content.first.content.upcase!
          coradoc
        end
      } end

      it { should_not include "hello" }
      it { should include "OLLEH" }
      it { should include "|===" }
    end

    context "#html_tree_add_hook_post_by_css" do
      let(:code) do -> {
        html_tree_add_hook_post_by_css "td" do |_, coradoc, _|
          coradoc.alignattr = ".>"
          coradoc
        end
      } end

      it { should include ".>|" }
    end
  end

  context "#postprocess_coradoc_tree" do
    let(:plugin) do
      c = code
      described_class.new do
        define_method(:postprocess_coradoc_tree) { instance_exec(&c) }
      end
    end

    context "visitor pattern" do
      let(:code) do -> {
        self.coradoc_tree = Coradoc::Element::Base.visit(coradoc_tree) do |elem,_dir|
          if elem.is_a? Coradoc::Element::Table::Cell
            elem.alignattr = ".>"
            elem
          else
            elem
          end
        end
      } end

      it { should include ".>|" }
    end
  end

  context "#postprocess_asciidoc_string" do
    let(:plugin) do
      c = code
      described_class.new do
        define_method(:postprocess_asciidoc_string) { instance_exec(&c) }
      end
    end

    context "replacement" do
      let(:code) do -> {
        self.asciidoc_string = asciidoc_string.gsub("|", ".>|")
      } end

      it { should include ".>|" }
    end
  end
end
