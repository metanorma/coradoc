# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Single source of truth for "which delimiter maps to which block model".
      #
      # The block rule in BlockRules delegates here to convert a parser
      # delimiter string (e.g., `----`, `****`, `--`) into the appropriate
      # Model::Block::* subclass instance. Adding a new block type means
      # appending one entry to DELIMITER_CLASSIFICATIONS — no edits to the
      # block rule itself. (Open/Closed Principle.)
      module BlockTypeClassifier
        # Each entry is [char, min_length, max_length, factory].
        # The factory is a callable taking (opts, attribute_list) and
        # returning a Model::Block::* instance. `max_length` nil means
        # unbounded.
        DELIMITER_CLASSIFICATIONS = [
          ['*', 4, nil, ->(opts, attrs) {
            if attrs && attrs.positional == [] && attrs.named.first&.name == 'reviewer'
              Model::Block::ReviewerComment.new(**opts.merge(attributes: attrs))
            else
              Model::Block::Side.new(**opts.merge(attributes: attrs))
            end
          }],
          ['=', 4, nil, ->(opts, attrs) { Model::Block::Example.new(**opts.merge(attributes: attrs)) }],
          ['+', 4, nil, ->(opts, attrs) { Model::Block::Pass.new(**opts.merge(attributes: attrs)) }],
          ['.', 4, nil, ->(opts, attrs) { Model::Block::Literal.new(**opts.merge(attributes: attrs)) }],
          ['_', 4, nil, ->(opts, attrs) { Model::Block::Quote.new(**opts.merge(attributes: attrs)) }],
          ['-', 4, nil, ->(opts, attrs) { Model::Block::SourceCode.new(**opts.merge(attributes: attrs)) }],
          ['-', 2, 2,  ->(opts, attrs) { Model::Block::Open.new(**opts.merge(attributes: attrs)) }]
        ].freeze

        module_function

        # @param delimiter [String] e.g., "----", "**", "--"
        # @param opts [Hash] Constructor options (id, title, lines, delimiter_len, ordering)
        # @param attrs [Model::AttributeList, nil]
        # @return [Model::Block::Base, nil]
        def classify(delimiter, opts, attrs)
          char = delimiter[0]
          len = delimiter.size
          entry = DELIMITER_CLASSIFICATIONS.find do |c, min_len, max_len, _|
            next false unless c == char
            next false unless len >= min_len
            next false if max_len && len > max_len

            true
          end
          return nil unless entry

          entry.last.call(opts, attrs)
        end
      end
    end
  end
end
