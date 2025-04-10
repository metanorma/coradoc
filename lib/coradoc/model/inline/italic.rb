# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class Italic < Base
        attribute :content, :string
        attribute :unconstrained, :boolean, default: -> { true }

        asciidoc do
          map_content to: :content
        end

        def to_asciidoc
          _content = Coradoc::Generator.gen_adoc(content)
          if unconstrained
            "__#{_content}__"
          else
            "_#{_content}_"
          end
        end
      end
    end
  end
end
