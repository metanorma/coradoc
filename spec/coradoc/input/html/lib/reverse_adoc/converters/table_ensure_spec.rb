require "spec_helper"

# We know better what syntax looks nice :)
# rubocop:disable all

describe Coradoc::ReverseAdoc::Converters::Table do
  let(:converter) { Coradoc::ReverseAdoc::Converters::Table.new }

  let(:c) { '<td colspan="1" rowspan="1"></td>' }
  let(:e) { '<td x-added="x-added"></td>' } # Added cell

  let(:c1x2) { '<td colspan="2" rowspan="1"></td>' }
  let(:c1x3) { '<td colspan="3" rowspan="1"></td>' }
  let(:c1x4) { '<td colspan="4" rowspan="1"></td>' }
  let(:c1x5) { '<td colspan="5" rowspan="1"></td>' }
  let(:c1x6) { '<td colspan="6" rowspan="1"></td>' }

  let(:c2) { '<td colspan="1" rowspan="2"></td>' }
  let(:c3) { '<td colspan="1" rowspan="3"></td>' }
  let(:c4) { '<td colspan="1" rowspan="4"></td>' }
  let(:c5) { '<td colspan="1" rowspan="5"></td>' }
  let(:c6) { '<td colspan="1" rowspan="6"></td>' }

  let(:c2x2) { '<td colspan="2" rowspan="2"></td>' }

  let(:ch) { '<td colspan="1" rowspan="1" width="50%"></td>' }
  let(:cq) { '<td colspan="1" rowspan="1" width="25%"></td>' }

  # Defaulting to document having 1000px width
  let(:cH) { '<td colspan="1" rowspan="1" width="500"></td>' }
  let(:cQ) { '<td colspan="1" rowspan="1" width="250"></td>' }

  let(:cN) { '<td colspan="1" rowspan="1" width="-250"></td>' }

  let(:h) { '<th colspan="1" rowspan="1"></th>' }

  let(:x) { "" } # Just a styling tool to visually show cell location.
  def r(*tds); "<tr>\n#{tds.reject(&:empty?).join("\n")}\n</tr>"; end
  def t(*trs); "<table>\n#{trs.join("\n")}\n</table>"; end
  def get_html(doc); doc.at_css("table").to_html; end

  shared_examples "should convert input to result" do
    it "should convert input to result" do
      tree = Nokogiri::HTML(input)
      converter.ensure_row_column_integrity_and_get_column_sizes(tree)
      result.should be == get_html(tree)
    end
  end

  shared_examples "should compute sizes correctly" do
    it "should compute sizes correctly" do
      tree = Nokogiri::HTML(input)
      my_sizes = converter.ensure_row_column_integrity_and_get_column_sizes(tree)
      my_sizes.should be == sizes
    end
  end

  shared_examples "should not cause error" do
    it "should not cause error" do
      tree = Nokogiri::HTML(input)
      converter.ensure_row_column_integrity_and_get_column_sizes(tree)
    end
  end

  context "adding fields" do
    let(:input) { t(
      r(h ,c ,c ,c ,c ,c ,),
      r(h ,c2x2 ,c ,c ,   ),
      r(h ,+++x ,c2x2 ,   ),
      r(h ,c    ,+++x ,   ),
    )}

    let(:result) { t(
      r(h ,c ,c ,c ,c ,c ,),
      r(h ,c2x2 ,c ,c ,e ,),
      r(h ,+++x ,c2x2 ,e ,),
      r(h ,c ,e ,+++x ,e ,),
    )}

    include_examples "should convert input to result"
  end

  context "trimming colspans" do
    let(:input) { t(
      r(c ,c ,),
      r(c1x2 ,),
      r(+++c1x3 ,),
      r(++++++c1x4 ,),
      r(+++++++++c1x5 ,),
      r(++++++++++++c1x6 ,),
    )}

    let(:result) { t(
      r(c ,c ,),
      r(c1x2 ,),
      r(c1x2 ,),
      r(c1x2 ,),
      r(c1x2 ,),
      r(c1x2 ,),
    )}

    let(:sizes) { 2 }

    include_examples "should convert input to result"
    include_examples "should compute sizes correctly"
  end

  context "trimming rowspans" do
    let(:input) { t(
      r(c ,c2,c3,c4,c5,c6),
      r(c ,+x,+x,+x,+x,+x),
              ## ## ## ##
                 ## ## ##
                    ## ##
                       ##
    )}

    let(:result) { t(
      r(c ,c2,c2,c2,c2,c2),
      r(c ,+x,+x,+x,+x,+x),
    )}

    include_examples "should convert input to result"
  end

  context "computing percentaged column widths" do
    let(:input) { t(
      r(cq,cq,ch,),
      r(c ,c ,c ,),
    )}

    let(:sizes) { "1,1,2" }

    include_examples "should compute sizes correctly"
  end

  context "computing percentaged column widths; filling voids" do
    let(:input) { t(
      r(cq,cq,c ,),
      r(c ,c ,c ,),
    )}

    let(:sizes) { "1,1,2" }

    include_examples "should compute sizes correctly"
  end

  context "computing percentaged column widths; even if colspans" do
    let(:input) { t(
      r(c2x2 ,c ,),
      r(+++x ,cq,),
      r(c ,c2x2 ,),
      r(cq,+++x ,),
      r(c ,c ,c ,),
      r(c ,c ,c ,),
    )}

    let(:sizes) { "1,2,1" }

    include_examples "should compute sizes correctly"
  end

  context "computing absolute column widths" do
    let(:input) { t(
      r(cQ,cQ,cH,),
      r(c ,c ,c ,),
    )}

    let(:sizes) { "1,1,2" }

    include_examples "should compute sizes correctly"
  end

  context "computing absolute column widths; scaling values" do
    let(:input) { t(
      r(cH,cH,c ,c ,), # Width would be 2000, but our document has width=1000
      r(c ,c ,cH,cH,),
    )}

    let(:sizes) { 4 }

    include_examples "should compute sizes correctly"
  end

  context "computing absolute column widths; ignoring negative values" do
    let(:input) { t(
      r(cQ,cN,cQ,),
      r(c, cN,c ,),
    )}

    let(:sizes) { "1,2,1" }

    include_examples "should compute sizes correctly"
  end

  context "converts a wild table correctly" do
    let(:input) { File.read("spec/reverse_adoc/assets/wild_table.html") }

    include_examples "should not cause error"
  end
end
