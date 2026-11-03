# frozen_string_literal: true

module Coradoc
  module Markdown
    # PARG bindings for the Markdown block grammar: which raw-tree rules
    # inflate directly to schema-generated model classes through
    # Coradoc::BindingInflater. Every other rule falls through to
    # Transformer (the residual), so the set below grows one rule at a
    # time as bindings replace hand-written transformation.
    #
    # The binding machinery proper (codegen-ed bindings, typed capture
    # assignment) is lutaml-model#1033. The table itself ships inside the
    # compiled artifact (grammar/coradoc-markdown.bindings.yml is its
    # sidecar source), so the inflater needs no side file at runtime.
    module Bindings
      class << self
        # @return [Coradoc::BindingInflater] the inflater for the bound rules
        def inflater
          @inflater ||= Coradoc::BindingInflater.from_table(
            Parser::Grammar.model_bindings,
            models: ->(name) { Schema.generated_class(name) }
          )
        end
      end
    end
  end
end
