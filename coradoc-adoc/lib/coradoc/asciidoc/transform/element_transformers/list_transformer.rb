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
                Coradoc::CoreModel::DefinitionList.new(
                  items: items,
                  source_line: list.source_line
                )
              else
                Coradoc::CoreModel::ListBlock.new(
                  marker_type: marker_type,
                  items: items,
                  source_line: list.source_line
                )
              end
            end

            private

            def transform_definition_item(item)
              term_parts = Array(item.terms)
              def_content = item.contents

              # Process each term independently so multi-term `<dt>`'s
              # (e.g. AsciiDoc `term1::\nterm2::\ndef`) preserve their
              # distinct identities in CoreModel#terms. Each entry in
              # `term_strings` is one term's plain text; `term_children`
              # is the parallel array of typed inline children. The
              # singular `term` accessor is set to the first term for
              # backward compatibility with consumers that haven't
              # migrated to the `terms` collection.
              term_strings = term_parts.map do |part|
                parsed = ToCoreModel.parse_inline_text(part)
                ToCoreModel.extract_text_content(ToCoreModel.transform_inline_content(parsed))
              end

              # Inline children for the FIRST term only. The CoreModel
              # `term_children` accessor is singular; carrying per-term
              # children for multi-term `<dt>`'s would require a
              # collection of arrays. The common case (single-term dt
              # with inline markup) is fully supported; multi-term dt
              # with inline markup on later terms degrades to text-only
              # for those later terms (acceptable per asciidoctor's
              # observed behaviour — multi-term inline markup is rare).
              primary_term_children = if term_parts.any?
                                        parsed = ToCoreModel.parse_inline_text(term_parts.first)
                                        ToCoreModel.transform_inline_content(parsed)
                                      else
                                        []
                                      end

              # contents is typed on DefinitionItem as Array<TextElement>
              # (see model/list/definition_item.rb). Each TextElement's
              # `to_s` handles the polymorphic content shape (String,
              # Array, or nested Serializable). Join the per-line text
              # elements into a single paragraph string so the inline
              # parser sees the full multi-line dd content as one
              # soft-wrapped paragraph.
              #
              # When dd has no inline definition (term-only item where
              # the dd is populated entirely by `+`-continuation blocks),
              # def_content is empty and we skip populating definitions
              # entirely — avoids emitting an empty <text></text> node
              # ahead of the attached blocks.
              def_text = def_content.map(&:to_s).reject(&:empty?).join(' ')
              has_definition = !def_text.empty?

              parsed_defs = has_definition ? ToCoreModel.parse_inline_text(def_text) : []
              def_children = has_definition ? ToCoreModel.transform_inline_content(parsed_defs) : []

              # Transform `+`-continuation blocks (paragraphs, admonitions,
              # delimited blocks) into their CoreModel equivalents. Each
              # becomes a child of the dd, rendered after the definition
              # paragraph. Passes through ToCoreModel.transform so any
              # registered block transformer applies (paragraph, source,
              # admonition, etc.).
              attached_children = Array(item.attached).filter_map do |block|
                ToCoreModel.transform(block)
              end

              primary_term = term_strings.first.to_s
              di = Coradoc::CoreModel::DefinitionItem.new(
                term: primary_term,
                terms: term_strings,
                definitions: has_definition ? [ToCoreModel.extract_text_content(def_children)] : [],
                term_children: primary_term_children,
                definition_children: def_children,
                attached_children: attached_children,
                source_line: item.source_line
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
                marker: item.marker,
                source_line: item.source_line
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
