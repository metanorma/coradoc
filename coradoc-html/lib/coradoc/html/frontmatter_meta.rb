# frozen_string_literal: true

require 'nokogiri'

module Coradoc
  module Html
    # Single source of truth for FrontmatterBlock -> HTML `<meta>` and
    # `<link>` tag mapping. (MECE: HTML-specific concerns live in the
    # HTML gem; CoreModel has no knowledge of HTML.)
    #
    # The module produces a small data structure that layout templates
    # and Nokogiri::HTML::Builder fallbacks both consume, so we never
    # duplicate the mapping rule across output paths (DRY).
    #
    # Mapping table (single source of truth — extend here only):
    #
    #   | Frontmatter key       | Output                                  |
    #   |-----------------------|-----------------------------------------|
    #   | title                 | <title> (caller decides title priority) |
    #   | author                | <meta name="author">                    |
    #   | description, excerpt  | <meta name="description">               |
    #   | date                  | <meta name="date"> (ISO 8601)           |
    #   | subject               | <meta name="subject">                   |
    #   | tags, categories      | <meta name="keywords"> (comma-joined)   |
    #   | $schema               | <link rel="schema.X" href="...">        |
    #   | (any other scalar)    | <meta name="<key>" content="<value>">   |
    module FrontmatterMeta
      Meta = Struct.new(:name, :content, keyword_init: true)
      LinkTag = Struct.new(:rel, :href, keyword_init: true)

      DESCRIPTION_KEYS = %w[description excerpt].freeze
      KEYWORDS_KEYS = %w[tags categories].freeze

      class << self
        # Extract a meta-tag list and link-tag list from a
        # FrontmatterBlock. `title` is returned separately so the caller
        # can decide precedence (e.g., document title vs. frontmatter).
        #
        # @param block [Coradoc::CoreModel::FrontmatterBlock, nil]
        # @return [Hash{Symbol=>Array<Meta>,Array<LinkTag>,String,nil}]
        #   { metas:, links:, title: }
        def extract(block)
          return empty_result unless block.is_a?(Coradoc::CoreModel::FrontmatterBlock)

          data = block.data || {}
          {
            metas: build_metas(data),
            links: build_links(block.schema),
            title: scalar_value(data['title'])
          }
        end

        # Emit meta + link tags into a Nokogiri head builder context.
        def emit_into_builder(builder_doc, block)
          data = extract(block)
          Array(data[:metas]).each do |meta|
            builder_doc.meta(name: meta.name, content: meta.content)
          end
          Array(data[:links]).each do |link|
            builder_doc.link(rel: link.rel, href: link.href)
          end
          data
        end

        private

        def empty_result
          { metas: [], links: [], title: nil }
        end

        def build_metas(data)
          metas = []
          consumed = []

          if (v = find_first_scalar(data, DESCRIPTION_KEYS))
            metas << Meta.new(name: 'description', content: v)
            consumed += DESCRIPTION_KEYS
          end
          if (v = find_first_array_as_csv(data, KEYWORDS_KEYS))
            metas << Meta.new(name: 'keywords', content: v)
            consumed += KEYWORDS_KEYS
          end
          if (v = find_first_scalar(data, %w[date]))
            metas << Meta.new(name: 'date', content: v)
            consumed << 'date'
          end
          if (v = find_first_scalar(data, %w[author]))
            metas << Meta.new(name: 'author', content: v)
            consumed << 'author'
          end
          if (v = find_first_scalar(data, %w[subject]))
            metas << Meta.new(name: 'subject', content: v)
            consumed << 'subject'
          end

          data.each do |key, value|
            next if consumed.include?(key) || key == 'title'

            content = scalar_value(value)
            next if content.nil? || content.empty?

            metas << Meta.new(name: key, content: content)
          end

          metas
        end

        def build_links(schema)
          return [] unless schema && !schema.to_s.strip.empty?

          [LinkTag.new(rel: 'schema.dublin_core', href: schema.to_s)]
        end

        def find_first_scalar(data, keys)
          keys.each do |k|
            value = data[k]
            next if value.nil?

            str = scalar_value(value)
            return str if str && !str.empty?
          end
          nil
        end

        def find_first_array_as_csv(data, keys)
          keys.each do |k|
            value = data[k]
            next if value.nil?

            csv = array_to_csv(value)
            return csv if csv && !csv.empty?
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
          return nil unless value.is_a?(Array)

          strings = value.map { |i| scalar_value(i) }.compact
          strings.any? ? strings.join(', ') : nil
        end
      end
    end
  end
end
