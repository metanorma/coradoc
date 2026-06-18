# frozen_string_literal: true

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module DefinitionList
          # Each strategy renders a full DefinitionList (with all items,
          # including nested ones) for a specific output form.
          #
          # Strategy is selected by inspecting the list: flat lists with
          # no nesting use Flat (PHP Markdown Extra); lists containing
          # any nesting use NestedHtml (HTML fallback per the spec).
          #
          # `config.definition_list_nested` overrides the auto choice:
          #   :html    → always NestedHtml when any nesting exists
          #   :flatten  → strip nesting (information loss; opt-in)
          class Base
            class << self
              def applies?(_list, _ctx)
                raise NotImplementedError
              end

              def render(_list, _ctx)
                raise NotImplementedError
              end

              def mode_name
                name.split('::').last.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym
              end
            end
          end
        end
      end
    end
  end
end
