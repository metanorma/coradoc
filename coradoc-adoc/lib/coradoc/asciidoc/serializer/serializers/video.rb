# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Video < Base
          def to_adoc(model, _options = {})
            @model = model
            _anchor = gen_anchor
            _title = model.title.nil? || model.title.empty? ? '' : ".#{model.title}\n"
            _attrs = model.attributes.to_adoc
            [_anchor, _title, 'video::', model.src, _attrs].join + model.line_break
          end

          private

          attr_reader :model

          def gen_anchor
            return '' unless @model.anchor

            anchor_str = @model.anchor.to_adoc
            anchor_str.empty? ? '' : "#{anchor_str}\n"
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Video, Serializers::Video)
    end
  end
end
