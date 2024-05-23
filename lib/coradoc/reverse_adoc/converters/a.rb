require "coradoc"

module Coradoc::ReverseAdoc
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

        return Coradoc::Element::Inline::Anchor.new(id) if id

        if href.to_s.start_with?("#")
          href = href.sub(/^#/, "").gsub(/\s/, "").gsub(/__+/, "_")
          return Coradoc::Element::Inline::CrossReference.new(href, name)
        end

        return name if href.to_s.empty?

        out = []
        out << " " if unconstrained_before?(node)
        out << Coradoc::Element::Inline::Link.new(path: href,
                                                  name: name.strip,
                                                  title: title.strip)
        out
      end
    end

    register :a, A.new
  end
end
