# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module List
        # Marker class for lists that can be nested inside a List::Item
        # via its +nested+ attribute. Inherits universal list attributes
        # (id, attrs) from List::Base.
        #
        # List::Definition does not extend Nestable because it has its own
        # nesting model via List::DefinitionItem#nested.
        class Nestable < Base
        end
      end
    end
  end
end
