require "yaml"

module Coradoc
  class Oscal
    attr_reader :_doc

    def initialize(document)
      @_doc = document
    end

    def self.to_oscal(document)
      new(document).to_oscal
    end

    def to_oscal
      {
        "metadata" => _doc.document_attributes.to_hash,
        "groups" => sections_as_groups,
      }
    end

    private

    # Organizational controls
    def sections_as_groups
      _doc.sections.map do |section|
        Hash.new.tap do |hash|
          hash["id"] = section.id
          hash["title"] = section.title&.content
          hash["controls"] = build_oscal_controls(section.sections)
        end
      end
    end

    # Clause 5.1
    def build_oscal_controls(sections)
      sections.map do |section|
        Hash.new.tap do |hash|
          hash["id"] = section.id
          # Use definition lists if present, otherwise fall back to glossaries
          props_items = if section.respond_to?(:definition_lists) && section.definition_lists && !section.definition_lists.empty?
                          section.definition_lists.first.items
                        elsif section.glossaries && !section.glossaries.empty?
                          section.glossaries.items
                        else
                          []
                        end
          hash["props"] = build_oscal_props(props_items)
          hash["parts"] = build_oscal_parts(section.sections)
        end
      end
    end

    # Control, Purpose, Guidance
    def build_oscal_parts(sections)
      sections.map do |section|
        Hash.new.tap do |hash|
          hash["id"] = section.id
          hash["name"] = section.title&.text
          hash["prose"] = build_oscal_prose(section.content)
          hash["parts"] = build_oscal_sub_parts(section.contents)
        end.compact
      end
    end

    def build_oscal_sub_parts(contents)
      if contents.length > 1
        parts = contents.select do |content|
          content if content.is_a?(Coradoc::Element::Paragraph)
        end

        parts.map do |part|
          Hash.new.tap do |hash|
            hash["id"] = part.id
            hash["prose"] = part.texts.join(" ")
          end
        end
      end
    end

    def build_oscal_props(attributes)
      attributes.map do |attribute|
        Hash.new.tap do |hash|
          hash["name"] = attribute.key.to_s.downcase
          hash["value"] = attribute.value
        end
      end
    end

    def build_oscal_prose(paragraph)
      paragraph&.texts&.join(" ")
    end
  end
end
