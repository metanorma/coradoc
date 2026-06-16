# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Nested definition list HTML rendering' do
  def convert(adoc)
    Coradoc.convert(adoc, from: :asciidoc, to: :html)
  end

  it 'renders flat definition list as dl/dt/dd' do
    html = convert("term1:: def1\nterm2:: def2\n")
    expect(html).to include('<dl>')
    expect(html).to include('<dt>term1</dt>')
    expect(html).to include('<dd>def1</dd>')
    expect(html).to include('<dt>term2</dt>')
    expect(html).to include('<dd>def2</dd>')
  end

  it 'renders nested ::: items as nested dl inside dd' do
    html = convert(<<~ADOC)
      parent:: parent def
      child::: child def
    ADOC

    expect(html).to include('<dt>parent</dt>')
    expect(html).to include('<dd>parent def</dd>')
    expect(html).to include('<dt>child</dt>')
    expect(html).to include('<dd>child def</dd>')
    expect(html.scan('<dl>').length).to eq(2)
    nested_pos = html.index('<dt>child</dt>')
    parent_dd_pos = html.index('<dd>parent def</dd>')
    inner_dl_pos = html.index('<dl>', parent_dd_pos)
    expect(inner_dl_pos).to be < nested_pos
  end

  it 'renders each ::: item as a separate entry (not collapsed)' do
    html = convert(<<~ADOC)
      parent:: top
      a::: alpha
      b::: beta
      c::: gamma
    ADOC

    %w[alpha beta gamma].each do |defn|
      expect(html).to include("<dd>#{defn}</dd>")
    end
    expect(html.scan('<dt>').length).to eq(4)
  end
end
