# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class Highlight < Base
        attribute :content, :string
        attribute :unconstrained, :boolean, default: -> { false }

        asciidoc do
          map_content to: :content
        end

        def to_asciidoc
          _content = Coradoc::Generator.gen_adoc(content)
          if unconstrained
            "###{_content}"
          else
            "##{_content}"
          end
        end
      end
    end
  end
end
