# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module List
          class DefinitionItem < Base
            def to_adoc(model, options_or_context = {})
              context = normalize_context(options_or_context)
              delimiter = context.option(:delimiter, '')
              _anchor = model.anchor.nil? ? '' : serialize_child(model.anchor, context)
              content = +''

              if model.terms && model.terms.size == 1
                t = serialize_child(model.terms.first, context)
                content << "#{_anchor}#{t}#{delimiter} "
              elsif model.terms && model.terms.size > 1
                # NOTE: When multiple terms exist, anchors are rendered on each term line
                # separately. Single term anchors are inlined with the definition.
                model.terms.each do |term|
                  t = serialize_child(term, context)
                  content << "#{t}#{delimiter}\n"
                end
              end

              d = model.contents ? serialize_children(model.contents, context) : ''
              content << "#{d}\n"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::List::DefinitionItem, List::DefinitionItem)
      end
    end
  end
end
