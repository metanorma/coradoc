# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Dl < Base
          def to_coradoc(node, state = {})
            items = process_dl(node, state)

            # Convert items to CoreModel::ListItem objects
            # For definition lists, term goes in content, definition goes in children
            list_items = items.map do |item|
              term_text = extract_text_from_content(item[:name])
              Coradoc::CoreModel::ListItem.new(
                content: term_text,
                children: item[:value]
              )
            end

            # Use CoreModel::ListBlock with marker_type "definition"
            Coradoc::CoreModel::ListBlock.new(
              marker_type: 'definition',
              items: list_items
            )
          end

          def process_dl(node, state = {})
            groups = []
            current = { name: [], value: [] }

            seen_dd = false
            child = node.at_xpath('*[1]')
            grandchild = nil
            until child.nil?
              if child.name == 'div'
                grandchild = child.at_xpath('*[1]')
                until grandchild.nil?
                  groups, current, seen_dd = process_dt_or_dd(
                    groups,
                    current,
                    seen_dd,
                    grandchild,
                    state
                  )
                  grandchild = grandchild.at_xpath('following-sibling::*[1]')
                end
              elsif %w[dt dd].include?(child.name)
                groups, current, seen_dd = process_dt_or_dd(
                  groups,
                  current,
                  seen_dd,
                  child,
                  state
                )
              end
              child = child.at_xpath('following-sibling::*[1]')
              groups << current if current[:name].any? && current[:value].any?
            end
            groups
          end

          def process_dt_or_dd(groups, current, seen_dd, subnode, state = {})
            if subnode.name == 'dt'
              if seen_dd
                # groups << current
                current = { name: [], value: [] }
                seen_dd = false
              end
              current[:name] += treat_children_coradoc(subnode, state)
            elsif subnode.name == 'dd'
              current[:value] += treat_children_coradoc(subnode, state)
              seen_dd = true
            end
            [groups, current, seen_dd]
          end

          # Extract text from content array
          def extract_text_from_content(content)
            return content if content.is_a?(String)
            return '' if content.nil?

            content.map do |item|
              case item
              when String
                item
              when Coradoc::CoreModel::InlineElement
                item.content.to_s
              when Coradoc::CoreModel::Base
                if item.respond_to?(:content)
                  item.content.to_s
                else
                  ''
                end
              else
                item.to_s
              end
            end.join
          end
        end

        register :dl, Dl.new
      end
    end
  end
end
