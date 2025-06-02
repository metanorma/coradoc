# frozen_string_literal: true

require "uri"

module Coradoc
  module Model
    module Inline
      class Link < Base
        attribute :path, :string
        attribute :title, :string
        attribute :name, :string
        attribute :right_constrain, :boolean, default: -> { false }

        asciidoc do
          map_model to: Coradoc::Element::Inline::Link
          map_attribute "path", to: :path
          map_attribute "title", to: :title
          map_attribute "name", to: :name
        end

        def to_asciidoc
          link = path.dup
          unless path&.match?(URI::DEFAULT_PARSER.make_regexp)
            link = "link:#{link}"
          end

          name_empty = name.nil? || name.empty?
          title_empty = title.nil? || title.empty?
          valid_empty_name_link = link.start_with?(%r{https?://})

          link << if name_empty && !title_empty
                    "[#{title}]"
                  elsif !name_empty
                    "[#{name}]"
                  elsif valid_empty_name_link && !right_constrain
                    ""
                  else
                    "[]"
                  end
          link
        end
      end
    end
  end
end
