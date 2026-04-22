# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Module containing header transformation rules
      module HeaderRules
        def self.apply(transformer_class)
          transformer_class.class_eval do
            # Header with author and revision
            rule(
              title: simple(:title),
              author: simple(:author),
              revision: simple(:revision)
            ) do
              id = title.respond_to?(:id) ? title.id : nil
              Model::Header.new(id:, title:, author:, revision:)
            end

            # Header with author only
            rule(
              title: simple(:title),
              author: simple(:author)
            ) do
              id = title.respond_to?(:id) ? title.id : nil
              Model::Header.new(id:, title:, author:, revision: nil)
            end

            # Header with revision only
            rule(
              title: simple(:title),
              revision: simple(:revision)
            ) do
              id = title.respond_to?(:id) ? title.id : nil
              Model::Header.new(id:, title:, author: nil, revision:)
            end

            # Header with title only
            rule(
              title: simple(:title)
            ) do
              id = title.respond_to?(:id) ? title.id : nil
              Model::Header.new(id:, title:, author: nil, revision: nil)
            end

            # Author
            rule(
              first_name: simple(:first_name),
              last_name: simple(:last_name),
              email: simple(:email)
            ) do
              Model::Author.new(first_name:, last_name:, email:, middle_name: nil)
            end

            # Revision
            rule(
              number: simple(:number),
              date: simple(:date),
              remark: simple(:remark)
            ) do
              Model::Revision.new(number:, date:, remark:)
            end

            # Unwrap header hash - handles cases where header wasn't transformed yet
            rule(header: subtree(:header)) do
              if header.is_a?(Hash) && header.key?(:title)
                id = header[:id]
                id = id.to_s unless id.nil?
                id = nil if id && id.empty?

                title = header[:title]
                author = header[:author]
                revision = header[:revision]

                id = title.id if title.respond_to?(:id) && title.id && !id

                Model::Header.new(id:, title:, author:, revision:)
              else
                header
              end
            end

            rule(header: simple(:header)) do
              header
            end
          end
        end
      end
    end
  end
end
