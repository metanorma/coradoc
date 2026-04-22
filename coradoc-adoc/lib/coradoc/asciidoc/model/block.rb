# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Block
        # Autoload block types lazily
        autoload :Core, 'coradoc/asciidoc/model/block/core'
        autoload :Example, 'coradoc/asciidoc/model/block/example'
        autoload :Literal, 'coradoc/asciidoc/model/block/literal'
        autoload :Listing, 'coradoc/asciidoc/model/block/listing'
        autoload :Open, 'coradoc/asciidoc/model/block/open'
        autoload :Pass, 'coradoc/asciidoc/model/block/pass'
        autoload :Quote, 'coradoc/asciidoc/model/block/quote'
        autoload :Side, 'coradoc/asciidoc/model/block/side'
        autoload :SourceCode, 'coradoc/asciidoc/model/block/source_code'
        autoload :ReviewerComment, 'coradoc/asciidoc/model/block/reviewer_comment'
      end
    end
  end
end
