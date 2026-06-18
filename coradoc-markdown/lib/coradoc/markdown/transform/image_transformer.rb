# frozen_string_literal: true

module Coradoc
  module Markdown
    module Transform
      module ImageTransformer
        class << self
          def transform_image(image)
            Coradoc::Markdown::Image.new(
              src: image.src,
              alt: image.alt.to_s
            )
          end
        end

        FromCoreModel.register(CoreModel::Image, method(:transform_image))
      end
    end
  end
end
