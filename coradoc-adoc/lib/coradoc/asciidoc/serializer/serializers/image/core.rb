# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Image
          class Core < Base
            def to_adoc(model, options = {})
              missing = if model.annotate_missing
                          "// Missing image: #{model.annotate_missing}\n"
                        else
                          ''
                        end
              _anchor = model.anchor.nil? ? '' : "#{serialize_child(model.anchor)}\n"
              _title = model.title.to_s.empty? ? '' : ".#{model.title}\n"
              attrs = serialize_child(model.attributes, options)
              [missing, _anchor, _title, 'image', model.colons, model.src, attrs,
               model.line_break].join
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Image::Core, Image::Core)
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Image::BlockImage, Image::Core)
      end
    end
  end
end
