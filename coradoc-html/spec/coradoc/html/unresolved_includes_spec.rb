# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Serialization with unresolved includes' do
  let(:doc) do
    Coradoc::CoreModel::DocumentElement.new(
      id: 'd', title: 'D',
      children: [Coradoc::CoreModel::Include.new(target: 'shared/common.adoc')]
    )
  end

  it 'raises UnresolvedIncludesError instead of silently dropping content' do
    expect { Coradoc.serialize(doc, to: :html) }
      .to raise_error(Coradoc::UnresolvedIncludesError, %r{shared/common\.adoc})
  end

  it 'can be bypassed explicitly with allow_unresolved_includes: true' do
    expect { Coradoc.serialize(doc, to: :html, allow_unresolved_includes: true) }
      .not_to raise_error
  end
end
