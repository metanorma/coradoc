# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/renderer'

RSpec.describe Coradoc::Html::Renderer, 'image rendering' do
  let(:renderer) { described_class.new }

  it 'renders block image as <figure> with <img>' do
    image = CoreModel::Image.new(src: 'photo.png', alt: 'A photo')
    html = renderer.render(image)
    expect(html).to include('<figure')
    expect(html).to include('<img src="photo.png"')
    expect(html).to include('alt="A photo"')
  end

  it 'renders block image with caption as <figcaption>' do
    image = CoreModel::Image.new(src: 'diagram.png', caption: 'Figure 1')
    html = renderer.render(image)
    expect(html).to include('<figcaption>')
    expect(html).to include('Figure 1')
  end

  it 'renders inline image without <figure>' do
    image = CoreModel::Image.new(src: 'icon.png', alt: 'Icon', inline: true)
    html = renderer.render(image)
    expect(html).not_to include('<figure')
    expect(html).to include('<img src="icon.png"')
  end

  it 'includes width and height' do
    image = CoreModel::Image.new(src: 'img.png', width: 200, height: 100)
    html = renderer.render(image)
    expect(html).to include('width="200"')
    expect(html).to include('height="100"')
  end
end
