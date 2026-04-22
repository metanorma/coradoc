# frozen_string_literal: true

module Coradoc
  module Markdown
    # Serializer for Markdown Document models.
    #
    # This serializer converts Document model objects back into
    # Markdown text format.
    #
    class Serializer
      # Serialize a document model to Markdown string
      #
      # @param document [Coradoc::Markdown::Base] The document or element to serialize
      # @param options [Hash] Serialization options
      # @return [String] The Markdown output
      def self.serialize(document, options = {})
        new.serialize(document, options)
      end

      # Serialize a document model to Markdown string
      #
      # @param element [Coradoc::Markdown::Base] The element to serialize
      # @param options [Hash] Serialization options
      # @return [String] The Markdown output
      def serialize(element, _options = {})
        case element
        when Document
          serialize_document(element)
        when Heading
          serialize_heading(element)
        when Paragraph
          serialize_paragraph(element)
        when List
          serialize_list(element)
        when CodeBlock
          serialize_code_block(element)
        when Blockquote
          serialize_blockquote(element)
        when Link
          serialize_link(element)
        when Image
          serialize_image(element)
        when HorizontalRule
          serialize_horizontal_rule(element)
        when Table
          serialize_table(element)
        when Emphasis
          serialize_emphasis(element)
        when Strong
          serialize_strong(element)
        when Code
          serialize_code(element)
        when DefinitionList
          serialize_definition_list(element)
        when Footnote
          serialize_footnote(element)
        when FootnoteReference
          serialize_footnote_reference(element)
        when Abbreviation
          serialize_abbreviation(element)
        when Model::AttributeList
          element.to_md
        when Model::Math
          element.to_md
        when Model::Extension
          element.to_md
        when String
          element
        else
          raise "Unknown element type for serialization: #{element.class}"
        end
      end

      private

      def serialize_document(doc)
        doc.blocks.map { |block| serialize(block) }.join("\n\n")
      end

      def serialize_heading(heading)
        "#{'#' * heading.level} #{heading.text}"
      end

      def serialize_paragraph(para)
        if para.children.any?
          para.children.map { |child| serialize_inline_content(child) }.join
        else
          para.text.to_s
        end
      end

      def serialize_inline_content(element)
        case element
        when String
          element
        when Emphasis, Strong, Code, Link, Image, FootnoteReference, Model::Math, Model::Extension
          serialize(element)
        else
          element.respond_to?(:to_md) ? element.to_md : element.to_s
        end
      end

      def serialize_list(list)
        marker = list.ordered ? '1.' : '-'
        list.items.map do |item|
          text = if item.children.any?
                   item.children.map { |child| serialize_inline_content(child) }.join
                 else
                   item.text.to_s
                 end
          if item.checked == true
            "- [x] #{text.sub(/^- \[[ x]\] /, '')}"
          elsif item.checked == false
            "- [ ] #{text.sub(/^- \[[ x]\] /, '')}"
          else
            "#{marker} #{text}"
          end
        end.join("\n")
      end

      def serialize_code_block(block)
        "```#{block.language}\n#{block.code}\n```"
      end

      def serialize_blockquote(quote)
        quote.content.to_s.lines.map { |line| "> #{line}" }.join
      end

      def serialize_link(link)
        "[#{link.text}](#{link.url}#{link.title ? " \"#{link.title}\"" : ''})"
      end

      def serialize_image(img)
        "![#{img.alt}](#{img.src}#{img.title ? " \"#{img.title}\"" : ''})"
      end

      def serialize_horizontal_rule(rule)
        rule.style || '---'
      end

      def serialize_table(table)
        return '' if table.headers.empty?

        header_row = "| #{table.headers.join(' | ')} |"
        separator = "| #{table.headers.map { |_| '---' }.join(' | ')} |"
        rows = table.rows.map { |row| "| #{Array(row).join(' | ')} |" }

        [header_row, separator, *rows].join("\n")
      end

      def serialize_emphasis(em)
        "*#{em.text}*"
      end

      def serialize_strong(strong)
        "**#{strong.text}**"
      end

      def serialize_code(code)
        "`#{code.text}`"
      end

      def serialize_definition_list(dl)
        dl.items.map do |term|
          lines = [term.text.to_s]
          term.definitions.each do |defn|
            lines << ": #{defn.content}"
          end
          lines.join("\n")
        end.join("\n\n")
      end

      def serialize_footnote(fn)
        content = fn.content.to_s
        "[^#{fn.id}]: #{content}"
      end

      def serialize_footnote_reference(ref)
        "[^#{ref.id}]"
      end

      def serialize_abbreviation(abbr)
        "*[#{abbr.term}]: #{abbr.definition}"
      end
    end
  end
end
