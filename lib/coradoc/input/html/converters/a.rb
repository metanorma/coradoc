require "coradoc"

module Coradoc
  module Input
    module Html
      module Converters
        class A < Base
          def to_coradoc(node, state = {})
            name  = treat_children(node, state)

            href  = node["href"]
            title = extract_title(node)
            id = node["id"] || node["name"]

            id = id&.gsub(/\s/, "")&.gsub(/__+/, "_")
            id = nil if id&.empty?

            return "" if /^_Toc\d+$|^_GoBack$/.match?(id)

            return Coradoc::Element::Inline::Anchor.new(id:) if id

            if href.to_s.start_with?("#")
              href = href.sub(/^#/, "").gsub(/\s/, "").gsub(/__+/, "_")
              return Coradoc::Element::Inline::CrossReference.new(
                href:,
                args: name,
              )
            end

            return name if href.to_s.empty?

            ambigous_characters = /[\w.?&#=%;\[\u{ff}-\u{10ffff}]/
            if name&.strip == href
              name = ""
              right_constrain = textnode_after_start_with?(
                node,
                ambigous_characters,
              )
            end

            out = []
            out << " " if textnode_before_end_with?(node, ambigous_characters)
            out << Coradoc::Element::Inline::Link.new(
              path: href,
              name: name.strip,
              title: title.strip,
              right_constrain: right_constrain,
            )
            out
          end
        end

        register :a, A.new
      end
    end
  end
end
