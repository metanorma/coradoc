# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class Superscript < Base
        attribute :content, :string

        asciidoc do
          map_content to: :content
        end

        def to_asciidoc
          _content = Coradoc::Generator.gen_adoc(content)
          # TODO: verify if this is the correct way to handle escape characters in superscript
          _content = Coradoc::Generator.escape_characters(
            _content,
            pass_through: %w[^],
          )

          if _content.empty?
            return ""
          end

          "^#{_content}^"
        end
      end
    end
  end
end
