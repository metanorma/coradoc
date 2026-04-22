# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Block
          class ReviewerComment < Core
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Block::ReviewerComment, Block::ReviewerComment)
      end
    end
  end
end
