# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module List
          class DefinitionItem < Base
            def to_adoc(model, options_or_context = {})
              context = normalize_context(options_or_context)
              delimiter = model.delimiter.to_s
              delimiter = context.option(:delimiter, '::') if delimiter.empty?
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

              nested_delimiter = "#{delimiter}:"
              Array(model.nested).each do |nested_list|
                next unless nested_list.is_a?(Coradoc::AsciiDoc::Model::List::Definition)

                nested_list.items.each do |nested_item|
                  content << serialize_with_options(nested_item, delimiter: nested_delimiter)
                end
              end

              content
            end

            private

            def serialize_with_options(child, options = {})
              serializer_class = ElementRegistry.lookup(child.class)
              serializer = serializer_class.new
              serializer.to_adoc(child, options)
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::List::DefinitionItem, List::DefinitionItem)
      end
    end
  end
end
