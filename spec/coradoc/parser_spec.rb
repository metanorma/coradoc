require "spec_helper"

RSpec.describe Coradoc::Parser do
  describe ".parse" do
    it "parses the asciidoc to standard doc" do
      sample_file = Coradoc.root_path.join(
        "spec", "fixtures", "sample-oscal.adoc"
      )

      document = described_class.parse(sample_file)
      ast = document[:document]

      expect(ast[0][:header][:title]).to eq("Catalog for ISO27002:2022")

      expect(ast[1][:document_attributes].count).to eq(5)
      expect(ast[1][:document_attributes][0][:key]).to eq("published")
      expect(ast[1][:document_attributes][0][:value]).to eq("'2023-03-08T09:51:08+08:00'")

      section = ast[3][:section]
      clause_5_1 = section[:sections][0][:section]
      content = clause_5_1[:contents].first

      expect(section[:title][:text]).to eq("Organizational controls")
      expect(content[:list][:definition_list][0][:definition_list_item][:terms][0][:dlist_term]).to eq("Clause")
      expect(content[:list][:definition_list][0][:definition_list_item][:definition]).to eq("5.1")
      expect(content[:list][:definition_list][6][:definition_list_item][:terms][0][:dlist_term]).to eq("Domain")
      expect(content[:list][:definition_list][6][:definition_list_item][:definition]).to eq("Governance_and_Ecosystem, Resilience")

      control_section = clause_5_1[:sections][0][:section]
      expect(control_section[:id]).to eq("control_5.1")
      expect(control_section[:title][:text]).to eq("Control")
      expect(control_section[:contents].count).to eq(1)
      expect(control_section[:contents][0][:paragraph]).not_to be_nil

      purpose_section = clause_5_1[:sections][1][:section]
      expect(purpose_section[:id]).to eq("purpose_5.1")
      expect(purpose_section[:title][:text]).to eq("Purpose")
      expect(purpose_section[:contents][0][:paragraph]).not_to be_nil

      guidance = clause_5_1[:sections][2][:section]
      expect(guidance[:contents].count).to eq(17)
      expect(guidance[:contents][0][:paragraph][:lines][0][:id]).to eq("guidance_5.1_part_1")
      expect(guidance[:contents][1][:paragraph][:lines][0][:id]).to eq("guidance_5.1_part_2")

      list_one_items = guidance[:contents][2][:list][:unordered]
      expect(list_one_items.count).to eq(3)
      expect(list_one_items[0][:list_item][:text]).not_to be_nil
      expect(list_one_items[0][:list_item][:id]).to eq("guidance_5.1_part_2_1")

      expect(guidance[:contents][3][:paragraph][:lines][0][:id]).not_to be_nil
      expect(guidance[:contents][4][:list][:unordered].count).to eq(7)
      expect(guidance[:contents][8][:list][:unordered].count).to eq(12)
      expect(guidance[:contents][10][:list][:unordered].count).to eq(6)
      expect(guidance[:contents][14][:paragraph]).not_to be_nil

      diff_table = guidance[:contents][15][:table]
      expect(diff_table[:title]).to eq("Differences between information security policy and topic-specific policy")
      expect(diff_table[:rows][0][:cols][0][:text]).to eq("  ")
      expect(diff_table[:rows][1][:cols][0][:text]).to eq("*Level of detail*")

      purpose_5_9 = section[:sections][8][:section][:sections][1][:section]
      highlight_5_9 = purpose_5_9[:contents][1][:paragraph]
      expect(highlight_5_9[:id]).to eq("scls_5-9")
      expect(highlight_5_9[:lines][0][:text][0][:span_constrained][:text]).to eq("Inventory")
    end
  end
end
