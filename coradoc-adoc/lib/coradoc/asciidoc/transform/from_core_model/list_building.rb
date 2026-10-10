# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # List construction for the AsciiDoc view: nested lists flatten
      # into the item stream with depth markers so AsciiDoc reads them
      # as nested rather than sibling lists (#68) — a marker-type
      # change alone signals nesting; same-type nesting goes one level
      # deeper.
      module ListBuilding
        def transform_list(list, depth = 1)
          items = []
          Array(list.items).each do |item|
            items << Coradoc::AsciiDoc::Model::List::Item.new(
              content: item.flat_text,
              marker: item.marker || (default_marker(list.marker_type) * depth)
            )
            nested_blocks = [item.nested_list,
                             *Array(item.children).grep(CoreModel::ListBlock)].compact
            nested_blocks.each do |child|
              child_depth = child.marker_type == list.marker_type ? depth + 1 : 1
              items.concat(transform_list(child, child_depth).items)
            end
          end

          case list.marker_type
          when 'ordered'
            Coradoc::AsciiDoc::Model::List::Ordered.new(items: items)
          when 'definition'
            Coradoc::AsciiDoc::Model::List::Definition.new(items: items)
          else
            Coradoc::AsciiDoc::Model::List::Unordered.new(items: items)
          end
        end

        def default_marker(marker_type)
          case marker_type
          when 'ordered' then '.'
          else '*'
          end
        end
      end
    end
  end
end
