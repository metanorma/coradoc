# frozen_string_literal: true

RSpec.shared_examples 'a liquid drop' do
  it 'returns self from to_liquid' do
    expect(drop.to_liquid).to equal(drop)
  end

  it 'exposes template_type as a non-empty string' do
    expect(drop.template_type).to be_a(String)
    expect(drop.template_type).not_to be_empty
  end

  it 'exposes the wrapped model' do
    expect(drop.model).to eq(model)
  end
end
