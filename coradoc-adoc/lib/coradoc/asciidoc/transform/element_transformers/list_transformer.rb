# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      module ElementTransformers
        class ListTransformer
          class << self
            def transform_list(list, marker_type)
              items = Array(list.items).map do |item|
                if item.is_a?(Coradoc::AsciiDoc::Model::List::DefinitionItem)
                  transform_definition_item(item)
                else
                  transform_list_item(item)
                end
              end

              if marker_type == 'definition'
                Coradoc::CoreModel::DefinitionList.new(items: items)
              else
                Coradoc::CoreModel::ListBlock.new(
                  marker_type: marker_type,
                  items: items
                )
              end
            end

            private

            def transform_definition_item(item)
              term_content = item.terms
              def_content = item.contents

              term_parts = term_content.is_a?(Array) ? term_content : [term_content]
              parsed_terms = term_parts.flat_map do |part|
                ToCoreModel.parse_inline_text(part)
              end

              parsed_defs = ToCoreModel.parse_inline_text(def_content)

              term_children = ToCoreModel.transform_inline_content(parsed_terms)
              def_children = ToCoreModel.transform_inline_content(parsed_defs)

              di = Coradoc::CoreModel::DefinitionItem.new(
                term: ToCoreModel.extract_text_content(term_children),
                definitions: [ToCoreModel.extract_text_content(def_children)],
                term_children: term_children,
                definition_children: def_children
              )
              di.id = item.id if item.id

              nested_adoc = Array(item.nested).find do |n|
                n.is_a?(Coradoc::AsciiDoc::Model::List::Definition) && n.items.any?
              end
              di.nested = transform_list(nested_adoc, 'definition') if nested_adoc

              di
            end

            def transform_list_item(item)
              content_val = item.content
              children = ToCoreModel.transform_inline_content(content_val)

              li = Coradoc::CoreModel::ListItem.new(
                content: ToCoreModel.extract_text_content(content_val),
                marker: item.marker
              )
              li.children = children

              nested_lists = extract_nested_lists(item)
              li.nested_list = nested_lists.first if nested_lists.size == 1
              li
            end

            # Pull every nested List::Core off the AsciiDoc model item and
            # transform each into a CoreModel::ListBlock. Returns [] when
            # the item has no nested lists. Single source of truth for the
            # nested-list shape so transform_list_item and any future caller
            # share the same extraction logic.
            def extract_nested_lists(item)
              nested = item.nested
              return [] if nested.nil?

              candidates = nested.is_a?(Array) ? nested : [nested]
              candidates.filter_map do |n|
                next unless n.is_a?(Coradoc::AsciiDoc::Model::List::Core)

                transform_list(n, list_marker_type(n))
              end
            end

            def list_marker_type(list)
              case list
              when Coradoc::AsciiDoc::Model::List::Ordered then 'ordered'
              when Coradoc::AsciiDoc::Model::List::Definition then 'definition'
              else 'unordered'
              end
            end
          end
        end
      end
    end
  end
end
