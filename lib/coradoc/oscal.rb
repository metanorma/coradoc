# Experimental
#
# Do not use this interface, this to test out incremental
# conversaion for the oscal document using the coradoc helper
#
# Once finalilzed we will probabelly remove this one
#
# require ""
#
require "json"
require "oscal"
require "coradoc/parser"

require "coradoc/asciidoc/header"
require "coradoc/asciidoc/section"
require "coradoc/asciidoc/bibdata"

module Coradoc
  class Oscal < Parslet::Parser
    include Coradoc::Asciidoc::Header
    include Coradoc::Asciidoc::Bibdata
    include Coradoc::Asciidoc::Section

    root :document
    rule(:document) do
      (
        bibdatas.as(:bibdata) |
        section.as(:section) |
        header.as(:header) |
        empty_line.as(:line_break) |
        any.as(:unparsed)
      ).repeat(1).as(:document)
    end

    def self.parse_to_yaml(filename)
      document = parse(filename)
      document_json = JSON.parse(document.to_json)
      document_json.to_yaml
    end


    def self.parse(filename)
      content = File.read(filename)
      ast = new.parse_with_debug(content)
      document = ast[:document]

      # Bibidata
      bibdata = Hash.new.tap do |hash|
        document[1][:bibdata].map do |data|
          hash[data[:key].to_s] = data[:value].to_s
        end
      end

      group_section = document[3][:section]
      group = Hash.new.tap do |hash|
        hash["id"] = group_section[:id].to_s
        hash["title"] = group_section[:title][:text].to_s
        hash["controls"] = []

        sections = group_section[:sections]
        sections.each do |section|
          hash["controls"] << Hash.new.tap do |shash|
            shash["id"] = section[:id].to_s
            shash["props"] = oscal_hash(section[:contents][0][:glossaries])
            shash["parts"] = build_parts(section[:sections])
          end
        end
      end

      require "securerandom"
      uuid = SecureRandom.uuid

      ::Oscal::Catalog.new(uuid, bibdata, nil, nil, group, nil)
    end

    def self.build_parts(sections)
      sections.map do |section|
        Hash.new.tap do |hash|
          hash["id"] = section[:id].to_s
          hash["name"] = section[:title][:text].to_s
          content = build_content(section[:contents])

          if content
            hash["prose"] = content.strip
          # else
          #   hash["parts"] = build_sub_parts(section[:contents])
          end
        end
      end
    end

    # def self.build_sub_parts(contents)
    #   if contents && contents.length > 2
    #     contents.select do |content|
    #       if content[:paragraph]
    #         Hash.new.tap do |hash|
    #           hash["id"] = content[:paragraph].first[:id]
    #           hash["prose"] = build_content([content])
    #         end
    #       end
    #     end
    #   end
    # end

    def self.build_content(contents)
      if contents && contents.length <= 2
        contents.first[:paragraph].map { |content| content[:text] }.join(" ")
      end
    end

    def self.oscal_hash(attributes)
      attributes.map do |attribute|
        Hash.new.tap do |hash|
          values = attribute[:value].to_s.split(",")
          hash["name"] = attribute[:key].to_s.downcase
          hash["value"] = values.length > 1 ? values.map(&:strip) : values.first
        end
      end
    end
  end
end
