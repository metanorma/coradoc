module Coradoc
  module Input
    module Html
      module Converters
        class H < Base
          def to_coradoc(node, state = {})
            id = node["id"]
            internal_anchor = treat_children_anchors(node, state)

            if id.to_s.empty? && internal_anchor.size.positive? && internal_anchor.first.respond_to?(:id)
              id = internal_anchor.first.id
            end

            level = node.name[/\d/].to_i
            content = treat_children_no_anchors(node, state)

            Coradoc::Element::Title.new(content, level, id: id)
          end

          def treat_children_no_anchors(node, state)
            node.children.reject { |a| a.name == "a" }.map do |child|
              treat_coradoc(child, state)
            end
          end

          def treat_children_anchors(node, state)
            node.children.select { |a| a.name == "a" }.map do |child|
              treat_coradoc(child, state)
            end
          end
        end

        register :h1, H.new
        register :h2, H.new
        register :h3, H.new
        register :h4, H.new
        register :h5, H.new
        register :h6, H.new
      end
    end
  end
end
