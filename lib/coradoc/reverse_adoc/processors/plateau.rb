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

            @doc
          end
        end
      end
    end
  end
end

Coradoc::ReverseAdoc.config.processor = Coradoc::ReverseAdoc::Processors::Plateau
