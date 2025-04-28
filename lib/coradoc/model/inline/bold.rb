# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class Bold < Base
        attribute :content, :string
        attribute :unconstrained, :boolean, default: -> { true }

        asciidoc do
          map_content to: :content
        end

        def to_asciidoc
          _content = Coradoc::Generator.gen_adoc(content)
          _content = Coradoc::Generator.escape_characters(_content, escape_chars: %w[*])

          if _content.empty?
            return ""
          end

          if unconstrained
            "**#{_content}**"
          else
            "*#{_content}*"
          end
        end
      end
    end
  end
end
