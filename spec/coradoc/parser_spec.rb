require "spec_helper"

RSpec.describe Coradoc::Parser do
  describe ".parse" do
    it "parses the asciidoc to standard doc" do
      sample_file = Coradoc.root_path.join(
        "spec", "fixtures", "sample-oscal.adoc"
      )

      document = Coradoc::Parser.parse(sample_file)
      ast = document[:document]

      expect(ast[0][:header][:title]).to eq("Catalog for ISO27002:2022")

      expect(ast[1][:bibdata].count).to eq(5)
      expect(ast[1][:bibdata][0][:key]).to eq("published")
      expect(ast[1][:bibdata][0][:value]).to eq("'2023-03-08T09:51:08+08:00'")

      section = ast[3][:section]
      clause_5_1 = section[:sections][0]
      content = clause_5_1[:contents].first

      expect(section[:title][:text]).to eq("Organizational controls")
      expect(content[:glossaries].first[:key]).to eq("Clause")
      expect(content[:glossaries].first[:value]).to eq("5.1")
      expect(content[:glossaries][6][:key]).to eq("Domain")
      expect(content[:glossaries][6][:value]).to eq("Governance_and_Ecosystem, Resilience")

      control_section = clause_5_1[:sections][0]
      expect(control_section[:id]).to eq("control_5.1")
      expect(control_section[:title][:text]).to eq("Control")
      expect(control_section[:contents].count).to eq(2)
      expect(control_section[:contents][0][:paragraph]).not_to be_nil

      purpose_section = clause_5_1[:sections][1]
      expect(purpose_section[:id]).to eq("purpose_5.1")
      expect(purpose_section[:title][:text]).to eq("Purpose")
      expect(purpose_section[:contents][0][:paragraph]).not_to be_nil

      guidance = clause_5_1[:sections][2]
      expect(guidance[:contents].count).to eq(28)
      expect(guidance[:contents][0][:paragraph][0][:id]).to eq("guidance_5.1_part_1")
      expect(guidance[:contents][2][:paragraph][0][:id]).to eq("guidance_5.1_part_2")

      list_one_items = guidance[:contents][4][:list][:unnumbered]
      expect(list_one_items.count).to eq(3)
      expect(list_one_items[0][:text]).not_to be_nil
      expect(list_one_items[0][:id]).to eq("guidance_5.1_part_2_1")

      expect(guidance[:contents][5][:paragraph][0][:id]).not_to be_nil
      expect(guidance[:contents][7][:list][:unnumbered].count).to eq(7)
      expect(guidance[:contents][14][:list][:unnumbered].count).to eq(12)
      expect(guidance[:contents][17][:list][:unnumbered].count).to eq(6)
      expect(guidance[:contents][24][:paragraph]).not_to be_nil

      diff_table = guidance[:contents][26][:table]
      expect(diff_table[:title]).to eq("Differences between information security policy and topic-specific policy")
      expect(diff_table[:rows][0][:cols][0][:text]).to eq("  ")
      expect(diff_table[:rows][1][:cols][0][:text]).to eq("*Level of detail*")

      purpose_5_9 = section[:sections][8][:sections][1]
      highlight_5_9 = purpose_5_9[:contents][2][:highlight]
      expect(highlight_5_9[:id]).to eq("scls_5-9")
      expect(highlight_5_9[:text]).to eq("Inventory")
    end
  end
end
