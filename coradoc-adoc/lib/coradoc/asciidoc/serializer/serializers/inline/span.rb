# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          class Span < Base
            def to_adoc(model, _options = {})
              if model.attributes
                attr_string = model.attributes.to_adoc
                if model.unconstrained
                  "#{attr_string}###{model.text}##"
                else
                  "#{attr_string}##{model.text}#"
                end
              elsif model.role
                if model.unconstrained
                  "[.#{model.role}]###{model.text}##"
                else
                  "[.#{model.role}]##{model.text}#"
                end
              else
                model.text.to_s
              end
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Inline::Span, Inline::Span)
      end
    end
  end
end
