# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          class CrossReference < Base
            def to_adoc(model, _options = {})
              if model.args&.length&.> 0
                _args = model.args.reject(&:empty?).map do |a|
                  serialize_child(a)
                end.join(',')

                return "<<#{model.href}>>" if _args.empty?

                return "<<#{model.href},#{_args}>>"

              end
              "<<#{model.href}>>"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Inline::CrossReference, Inline::CrossReference)
      end
    end
  end
end
