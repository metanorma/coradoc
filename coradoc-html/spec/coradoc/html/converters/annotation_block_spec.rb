# frozen_string_literal: true

require 'coradoc/html'
require 'coradoc/core_model'

RSpec.describe 'AnnotationBlock HTML conversion' do
  describe 'dispatch ordering' do
    it 'routes AnnotationBlock to render_core_annotation_block, not render_core_block' do
      annotation = Coradoc::CoreModel::AnnotationBlock.new(
        annotation_type: 'note',
        content: 'Important detail'
      )

      html = Coradoc::Html::Converters::Base.convert_content_to_html(annotation)

      # AnnotationBlock should produce admonition markup, not a plain <p>
      expect(html).to include('admonition')
      expect(html).to include('note')
      expect(html).to include('Important detail')
    end
  end

  describe 'render_core_annotation_block' do
    it 'renders NOTE with type class and uppercase label' do
      annotation = Coradoc::CoreModel::AnnotationBlock.new(
        annotation_type: 'note',
        content: 'This is a note'
      )

      html = Coradoc::Html::Converters::Base.convert_content_to_html(annotation)

      expect(html).to include('class="admonition note"')
      expect(html).to include('admonition-label')
      expect(html).to include('NOTE')
      expect(html).to include('This is a note')
    end

    it 'renders WARNING annotation' do
      annotation = Coradoc::CoreModel::AnnotationBlock.new(
        annotation_type: 'warning',
        content: 'Danger ahead'
      )

      html = Coradoc::Html::Converters::Base.convert_content_to_html(annotation)

      expect(html).to include('class="admonition warning"')
      expect(html).to include('WARNING')
    end

    it 'renders annotation with custom label' do
      annotation = Coradoc::CoreModel::AnnotationBlock.new(
        annotation_type: 'reviewer',
        annotation_label: 'john.doe',
        content: 'Please review'
      )

      html = Coradoc::Html::Converters::Base.convert_content_to_html(annotation)

      expect(html).to include('class="admonition reviewer"')
      expect(html).to include('john.doe')
    end

    it 'renders annotation with id attribute' do
      annotation = Coradoc::CoreModel::AnnotationBlock.new(
        annotation_type: 'tip',
        id: 'helpful-tip',
        content: 'Use Ruby 3.x'
      )

      html = Coradoc::Html::Converters::Base.convert_content_to_html(annotation)

      expect(html).to include('id="helpful-tip"')
    end
  end
end
