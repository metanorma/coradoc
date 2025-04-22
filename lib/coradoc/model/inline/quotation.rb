# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class Quotation < Base
        attribute :content, :string

        asciidoc do
          map_content to: :content
        end

        def to_asciidoc
          _content = Coradoc::Generator.gen_adoc(content)
          "#{_content[/^\s*/]}\"#{_content.strip}\"#{_content[/(?<!\s)\s*+$/]}"
        end
      end
    end
  end
end
