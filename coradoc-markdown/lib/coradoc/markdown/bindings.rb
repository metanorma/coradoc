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
    # assignment) is lutaml-model#1033; these declarations are the data
    # it will back.
    module Bindings
      # Thematic break: `{hr: true}` -> HorizontalRule(style: '---').
      THEMATIC_BREAK = Coradoc::BindingInflater::Binding.new(
        keys: [:hr],
        model: -> { Schema.generated_class('HorizontalRule') },
        captures: {},
        defaults: { style: '---' }
      )

      class << self
        # @return [Coradoc::BindingInflater] the inflater for the bound rules
        def inflater
          @inflater ||= Coradoc::BindingInflater.new(bindings: [THEMATIC_BREAK])
        end
      end
    end
  end
end
