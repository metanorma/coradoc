# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Ol < Base
          def to_coradoc(node, state = {})
            id = node['id']
            ol_count = state.fetch(:ol_count, 0) + 1
            items = treat_children_coradoc(
              node,
              state.merge(ol_count: ol_count)
            )

            marker_type = get_list_type(node, state)

            Coradoc::CoreModel::ListBlock.new(
              marker_type: marker_type,
              items: items,
              id: id,
              start: node['start']&.to_i
            )
          end

          def get_list_type(node, _state)
            case node.name
            when 'ol'
              'ordered'
            when 'ul'
              'unordered'
            when 'dir'
              'unordered'
            else
              'unordered'
            end
          end
        end

        register :ol, Ol.new
        register :ul, Ol.new
        register :dir, Ol.new
      end
    end
  end
end
