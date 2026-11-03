# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    # PARG bindings for the AsciiDoc grammar (M3 of the parg-bindings
    # migration): raw-tree rules that inflate straight to model classes
    # through Coradoc::BindingInflater. Every rule not listed here is
    # still handled by Transformer's rule modules (the residual), so the
    # set grows one rule at a time and each bound rule retires its
    # transformer rule.
    #
    # Semantic steps live in small named hooks (`via:`) in Hooks; a hook
    # that keeps growing is a grammar-shape problem, not a hook problem.
    module Bindings
      Binding = Coradoc::BindingInflater::Binding

      # Named hooks: the ~20% of rules that are not pure
      # capture-to-attribute wiring.
      module Hooks
        module_function

        # Header: flatten the raw `{title:, author:, revision:}` capture
        # and inherit the id from a Title model when the header has none.
        def header(attributes)
          raw = attributes.fetch(:header)
          title = raw[:title]
          id = raw[:id]
          id = title.id if title.is_a?(Model::Title) && title.id && !id
          id = id.to_s unless id.nil?
          id = nil if id&.empty?

          { id:, title:, author: raw[:author], revision: raw[:revision] }
        end

        # Paragraph: raw `lines` become TextElements (same-line joins and
        # inline arrays are normalised by Transformer.lines_to_text_elements).
        def paragraph(attributes)
          raw = attributes.fetch(:paragraph)
          {
            content: Transformer.lines_to_text_elements(raw[:lines]),
            id: raw[:id],
            attributes: raw[:attribute_list],
            title: raw[:title]
          }
        end
      end

      HEADER = Binding.new(
        keys: [:header],
        model: -> { Model::Header },
        captures: { header: :header },
        defaults: {},
        via: Hooks.method(:header)
      )

      PARAGRAPH = Binding.new(
        keys: [:paragraph],
        model: -> { Model::Paragraph },
        captures: { paragraph: :paragraph },
        defaults: {},
        via: Hooks.method(:paragraph)
      )

      AUTHOR = Binding.new(
        keys: %i[first_name last_name email],
        model: -> { Model::Author },
        captures: { first_name: :first_name, last_name: :last_name, email: :email },
        defaults: { middle_name: nil }
      )

      REVISION = Binding.new(
        keys: %i[number date remark],
        model: -> { Model::Revision },
        captures: { number: :number, date: :date, remark: :remark },
        defaults: {}
      )

      # Rules bound so far, in migration order (header -> paragraphs ->
      # lists -> inline).
      ALL = [HEADER, AUTHOR, REVISION, PARAGRAPH].freeze

      class << self
        # @return [Coradoc::BindingInflater] the inflater for the bound rules
        def inflater
          @inflater ||= Coradoc::BindingInflater.new(bindings: ALL)
        end
      end
    end
  end
end
