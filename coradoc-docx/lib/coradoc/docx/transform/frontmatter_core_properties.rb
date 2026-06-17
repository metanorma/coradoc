# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      # Single source of truth for FrontmatterBlock -> OOXML core
      # properties mapping. (MECE: DOCX-specific concerns live in the
      # DOCX gem; CoreModel has no knowledge of OOXML.)
      #
      # Uniword's DocumentBuilder exposes setter methods (title, author,
      # subject, keywords, description, date_field) that write the
      # docProps/core.xml Dublin Core elements. This module reads
      # FrontmatterBlock entries and invokes the right setters, so the
      # mapping table lives in exactly one place.
      #
      # Mapping table (single source of truth):
      #
      #   | Frontmatter key       | OOXML element        | Builder method |
      #   |-----------------------|----------------------|----------------|
      #   | title                 | dc:title             | title          |
      #   | author                | dc:creator           | author         |
      #   | date                  | dc:date              | created        |
      #   | description, excerpt  | dc:description       | description    |
      #   | subject               | dc:subject           | subject        |
      #   | tags, categories      | cp:keywords          | keywords       |
      module FrontmatterCoreProperties
        DESCRIPTION_KEYS = %w[description excerpt].freeze
        KEYWORDS_KEYS = %w[tags categories].freeze

        class << self
          # Apply FrontmatterBlock data to a Uniword DocumentBuilder.
          # Skips nil/empty values. Does not overwrite builder values
          # that the caller has set explicitly (caller invokes this
          # AFTER setting document.title, for example).
          #
          # @param builder [Uniword::Builder::DocumentBuilder]
          # @param block [Coradoc::CoreModel::FrontmatterBlock, nil]
          # @return [void]
          def apply(builder, block)
            return unless block.is_a?(Coradoc::CoreModel::FrontmatterBlock)

            data = block.data || {}

            if (v = find_first_scalar(data, KEYWORDS_KEYS))
              builder.keywords(v)
            end
            if (v = find_first_scalar(data, %w[author]))
              builder.author(v)
            end
            if (v = find_first_scalar(data, %w[subject]))
              builder.subject(v)
            end
            if (v = find_first_scalar(data, DESCRIPTION_KEYS))
              builder.description(v)
            end
            if (v = find_first_scalar(data, %w[date]))
              builder.created(v)
            end
          end

          # Locate the FrontmatterBlock in a DocumentElement's children,
          # if any.
          #
          # @param document [Coradoc::CoreModel::DocumentElement]
          # @return [Coradoc::CoreModel::FrontmatterBlock, nil]
          def extract(document)
            return nil unless document.is_a?(Coradoc::CoreModel::DocumentElement)

            Array(document.children).find { |c| c.is_a?(Coradoc::CoreModel::FrontmatterBlock) }
          end

          private

          def find_first_scalar(data, keys)
            keys.each do |k|
              value = data[k.to_s]
              next if value.nil?

              str = scalar_value(value)
              return str if str && !str.empty?
            end
            nil
          end

          def scalar_value(value)
            return nil if value.nil?

            case value
            when String then value
            when Integer, Float, TrueClass, FalseClass then value.to_s
            when Date, Time, DateTime then value.iso8601
            when Symbol then value.to_s
            when Array then array_to_csv(value)
            when Hash then nil
            else value.to_s
            end
          end

          def array_to_csv(value)
            strings = value.map { |i| scalar_value(i) }.compact
            strings.any? ? strings.join(', ') : nil
          end
        end
      end
    end
  end
end
