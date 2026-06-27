# frozen_string_literal: true

module Coradoc
  module Html
    module TagMapping
      ELEMENT_TO_TAG = {
        # Sections
        section: 'section',
        header: 'header',

        # Blocks
        paragraph: 'p',
        example: 'div',
        sidebar: 'aside',
        quote: 'blockquote',
        verse: 'div',
        listing: 'pre',
        literal: 'pre',
        source: 'pre',
        source_code: 'pre',
        open: 'div',
        horizontal_rule: 'hr',
        comment: 'div',
        pass: 'div',
        reviewer: 'div',

        # Lists
        ordered_list: 'ol',
        unordered_list: 'ul',
        list_item: 'li',
        description_list: 'dl',
        description_term: 'dt',
        description_detail: 'dd',

        # List marker type aliases (from ListBlock#marker_type)
        ordered: 'ol',
        unordered: 'ul',
        definition: 'dl',

        # Tables
        table: 'table',
        table_row: 'tr',
        table_cell: 'td',
        table_header: 'th',

        # Inline formatting (symbol keys from TagMapping, string keys from format_type)
        bold: 'strong',
        italic: 'em',
        monospace: 'code',
        highlight: 'mark',
        superscript: 'sup',
        subscript: 'sub',
        underline: 'u',
        strikethrough: 'del',
        small_caps: 'span',

        # Inline format type aliases (from InlineElement#resolve_format_type)
        link: 'a',
        xref: 'a',
        footnote: 'sup',
        span: 'span',
        term: 'span',
        quotation: 'q',
        small: 'small',
        stem: 'code',
        attribute_reference: 'span',

        # Links (semantic names)
        anchor: 'a',
        cross_reference: 'a',

        # Media
        image: 'img',
        video: 'video',
        audio: 'audio',

        # Other
        break: 'hr',
        line_break: 'br',
        admonition: 'div'
      }.freeze

      ELEMENT_CSS_CLASS = {
        example: 'example',
        sidebar: 'sidebar',
        literal: 'literal',
        stem: 'stem',
        term: 'term'
      }.freeze

      def self.tag_for(element_type)
        return 'div' if element_type.nil?

        key = element_type.is_a?(Symbol) ? element_type : element_type.to_sym
        ELEMENT_TO_TAG[key] || 'div'
      end

      def self.css_class_for(element_type)
        return nil if element_type.nil?

        key = element_type.is_a?(Symbol) ? element_type : element_type.to_sym
        ELEMENT_CSS_CLASS[key]
      end
    end
  end
end
