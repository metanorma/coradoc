# frozen_string_literal: true

module Coradoc
  module Model
    module Block
      class Core < Attached
        include Coradoc::Model::Anchorable

        attribute :id, :string
        attribute :title, :string
        attribute :attributes, AttributeList, default: -> { AttributeList.new }
        attribute :lines, :string, collection: true, initialize_empty: true
        attribute :delimiter, :string
        attribute :delimiter_char, :string
        attribute :delimiter_len, :integer
        attribute :lang, :string
        attribute :type_str, :string

        # TODO: and many methods from Coradoc::Element::Block::Core

        def gen_title
          t = Coradoc::Generator.gen_adoc(title)
          return "" if t.nil? || t.empty?

          ".#{t}\n"
        end

        def gen_attributes
          attrs = attributes.to_asciidoc(show_empty: false)
          return "#{attrs}\n" if !attrs.empty?

          ""
        end

        def gen_delimiter
          delimiter_char * delimiter_len
        end

        def gen_lines
          lines.map do |line|
            Coradoc::Generator.gen_adoc(line)
          end.join("\n")
        end
      end
    end
  end
end
