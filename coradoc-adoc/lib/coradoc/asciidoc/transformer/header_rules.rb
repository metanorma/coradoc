# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Module containing header transformation rules
      module HeaderRules
        def self.apply(transformer_class)
          transformer_class.class_eval do
            # Header — single canonical rule covering all combinations of
            # optional :author and :revision slots. The previous design had
            # four explicit rules (one per combination); this version reads
            # the same data with one `subtree` match.
            rule(header: subtree(:header)) do
              title = header[:title]
              author = header[:author]
              revision = header[:revision]

              id = header[:id]
              id = title.id if title.is_a?(Model::Title) && title.id && !id
              id = id.to_s unless id.nil?
              id = nil if id && id.empty?

              Model::Header.new(
                id:, title:, author:, revision:,
                source_line: SourceLineExtractor.extract(header)
              )
            end

            rule(header: simple(:header)) do
              header
            end

            # Author
            rule(
              first_name: simple(:first_name),
              last_name: simple(:last_name),
              email: simple(:email)
            ) do
              Model::Author.new(
                first_name:, last_name:, email:, middle_name: nil,
                source_line: SourceLineExtractor.extract(first_name)
              )
            end

            # Revision
            rule(
              number: simple(:number),
              date: simple(:date),
              remark: simple(:remark)
            ) do
              Model::Revision.new(
                number:, date:, remark:,
                source_line: SourceLineExtractor.extract(number)
              )
            end
          end
        end
      end
    end
  end
end
