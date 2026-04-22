# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload block serializers
        module Block
          autoload :Core, 'coradoc/asciidoc/serializer/serializers/block/core'
          autoload :Example, 'coradoc/asciidoc/serializer/serializers/block/example'
          autoload :Listing, 'coradoc/asciidoc/serializer/serializers/block/listing'
          autoload :Literal, 'coradoc/asciidoc/serializer/serializers/block/literal'
          autoload :Open, 'coradoc/asciidoc/serializer/serializers/block/open'
          autoload :Pass, 'coradoc/asciidoc/serializer/serializers/block/pass'
          autoload :Quote, 'coradoc/asciidoc/serializer/serializers/block/quote'
          autoload :ReviewerComment, 'coradoc/asciidoc/serializer/serializers/block/reviewer_comment'
          autoload :Side, 'coradoc/asciidoc/serializer/serializers/block/side'
          autoload :SourceCode, 'coradoc/asciidoc/serializer/serializers/block/source_code'
        end
      end
    end
  end
end
