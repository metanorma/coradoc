# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      # Handles CommentBlock → omitted (comments are not rendered).
      module Comment
        def self.call(_element, context:)
          nil
        end
      end
    end
  end
end
