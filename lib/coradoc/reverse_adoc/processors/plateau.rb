module Coradoc
  module ReverseAdoc
    module Processors
      module Plateau
        class Preprocessor
          def self.call(ng)
            new(ng).process
          end

          def initialize(ng)
            @doc = ng
          end

          def process
            # Remove side menu, so we can generate TOC ourselves
            @doc.at_css(".sideMenu").remove

            # Correct non-semantic classes into semantic HTML tags
            @doc.css(".titledata").each do |e|
              e.name = "h2"
            end

            @doc.css(".subtitledata").each do |e|
              e.name = "h3"
            end

            @doc.css(".pitemdata").each do |e|
              e.name = "h4"
            end

            @doc.css(".sitemdata").each do |e|
              e.name = "h5"
            end

            @doc.css('td[bgcolor="#D0CECE"]').each do |e|
              e.name = "th"
            end

            # Convert table/img caption to become a caption
            @doc.css(".imagedata").each do |e|
              table = e.parent.next&.children&.first
              if table&.name == "table"
                e.name = "caption"
                table.prepend_child(e)
                next
              end

              img = e.parent.previous&.children&.first
              if img&.name == "img"
                title = e.text.strip
                img["title"] = title
                e.remove
                next
              end

              ### We shouldn't be here
            end

            @doc
          end
        end
      end
    end
  end
end

Coradoc::ReverseAdoc.config.processor = Coradoc::ReverseAdoc::Processors::Plateau
