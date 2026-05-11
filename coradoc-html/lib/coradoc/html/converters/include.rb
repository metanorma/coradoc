# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Include < Base
        def self.to_html(include_directive, _options = {})
          return '' unless include_directive

          path = escape_html(include_directive.metadata&.dig(:path) || '')

          comment_text = "include::#{path}[]"

          attrs = include_directive.metadata&.dig(:attributes) || {}
          if attrs && !attrs.empty?
            attrs_str = attrs.map { |k, v| "#{k}=#{v}" }.join(',')
            comment_text = "include::#{path}[#{attrs_str}]" unless attrs_str.empty?
          end

          doc = Nokogiri::HTML::DocumentFragment.parse('')
          comment = Nokogiri::XML::Comment.new(doc, " #{comment_text} ")
          doc.add_child(comment)
          doc.to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.comment?

          text = element.text.to_s.strip
          return nil unless text.match?(/^include::/)

          return unless text =~ /^include::([^\[]+)(\[([^\]]*)\])?/

          path = ::Regexp.last_match(1).strip
          attrs_str = ::Regexp.last_match(3)

          attrs = {}
          if attrs_str && !attrs_str.empty?
            attrs_str.split(',').each do |attr|
              if attr.include?('=')
                k, v = attr.split('=', 2)
                attrs[k.strip.to_sym] = v.strip
              end
            end
          end

          Coradoc::CoreModel::Block.new(
            block_semantic_type: 'include',
            content: path,
            metadata: {
              path: path,
              attributes: attrs
            }
          )
        end
      end
    end
  end
end
