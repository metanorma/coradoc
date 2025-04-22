# frozen_string_literal: true

module Coradoc
  module Model
    module List
      class Unordered < Core
        def prefix
          return marker if marker

          "*" * [ol_count, 1].max
        end
      end
    end
  end
end
