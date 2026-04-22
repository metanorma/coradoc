# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class AttributeList < Base
          def to_adoc(model, options_or_context = {})
            context = normalize_context(options_or_context)
            show_empty = context.option(:show_empty, true)

            valid_positional = model.positional.reject.with_index do |_p, i|
              model.rejected_positional.any? { |r| r.position == i }
            end

            valid_named = model.named.reject do |n|
              model.rejected_named.any? { |r| r.name == n.name }
            end

            adoc = [valid_positional,
                    valid_named].flatten.map { |a| serialize_child(a, context) }.join(',')

            if adoc.empty? && show_empty
              '[]'
            elsif adoc.empty?
              ''
            else
              "[#{adoc}]"
            end
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::AttributeList, Serializers::AttributeList)
      # Also register for Image::Core::AttributeList which inherits from AttributeList
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Image::Core::AttributeList, Serializers::AttributeList)
    end
  end
end
