# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class Subscript < Base
        attribute :content, :string

        asciidoc do
          map_content to: :content
        end

        def to_asciidoc
          _content = Coradoc::Generator.gen_adoc(content)
          "~#{_content}~"
        end
      end
    end
  end
end
