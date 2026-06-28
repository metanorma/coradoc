# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class List < ElementSerializer
          handles_type ::Coradoc::Markdown::List

          def call(element, _ctx)
            marker = element.ordered ? '1.' : '-'
            element.items.flat_map do |item|
              lines = [render_item(item, marker, _ctx)]
              lines += call(item.sublist, _ctx).split("\n").map { |l| "    #{l}" } if item.sublist
              lines
            end.join("\n")
          end

          private

          def render_item(item, marker, ctx)
            text = serialize_item_text(item, ctx)
            if item.checked == true
              "- [x] #{text.sub(/^- \[[ x]\] /, '')}"
            elsif item.checked == false
              "- [ ] #{text.sub(/^- \[[ x]\] /, '')}"
            else
              "#{marker} #{text}"
            end
          end

          def serialize_item_text(item, ctx)
            return item.text.to_s unless item.children.any?

            ctx.serialize_inline_join(item.children)
          end
        end
      end
    end
  end
end
