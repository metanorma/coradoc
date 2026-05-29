# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/section_numberable'

RSpec.describe Coradoc::Html::SectionNumberable do
  let(:klass) do
    Struct.new(:id) do
      include Coradoc::Html::SectionNumberable
    end
  end

  it 'provides section_number attr_accessor' do
    instance = klass.new('test')
    expect(instance).to respond_to(:section_number)
    expect(instance).to respond_to(:section_number=)
  end

  it 'defaults section_number to nil' do
    instance = klass.new('test')
    expect(instance.section_number).to be_nil
  end

  it 'allows setting and reading section_number' do
    instance = klass.new('test')
    instance.section_number = '1.2.3'
    expect(instance.section_number).to eq('1.2.3')
  end
end
