# frozen_string_literal: true

require 'coradoc'

module Coradoc
  module Input
    module Html
      module Converters
        class A < Base
          def to_coradoc(node, state = {})
            # Use treat_children_coradoc to get CoreModel elements
            content = treat_children_coradoc(node, state)

            href  = node['href']
            title = extract_title(node)
            id = node['id'] || node['name']

            id = id&.gsub(/\s/, '')&.gsub(/__+/, '_')
            id = nil if id&.empty?

            return nil if /^_Toc\d+$|^_GoBack$/.match?(id)

            # For inline anchors - return CoreModel InlineElement with format_type "anchor"
            if id
              return Coradoc::CoreModel::InlineElement.new(
                format_type: 'anchor',
                target: id
              )
            end

            # For cross-references
            if href.to_s.start_with?('#')
              ref_id = href.sub(/^#/, '').gsub(/\s/, '').gsub(/__+/, '_')
              # Convert content to string
              content_str = if content.is_a?(Array)
                              content.map { |c| c.respond_to?(:content) ? c.content : c.to_s }.join
                            else
                              content.to_s
                            end
              return Coradoc::CoreModel::InlineElement.new(
                format_type: 'xref',
                target: ref_id,
                content: content_str.strip.empty? ? nil : content_str.strip
              )
            end

            return nil if href.to_s.empty?

            # For links
            ambigous_characters = /[\w.?&#=%;\[\u{ff}-\u{10ffff}]/
            right_constrain = textnode_after_start_with?(node, ambigous_characters)

            # Convert content to string for the link
            content_str = if content.is_a?(Array)
                            content.map { |c| c.respond_to?(:content) ? c.content : c.to_s }.join
                          else
                            content.to_s
                          end

            out = []
            # Add leading space if needed
            if textnode_before_end_with?(node, ambigous_characters)
              out << Coradoc::CoreModel::InlineElement.new(
                format_type: 'text',
                content: ' '
              )
            end

            # Create link element
            link = Coradoc::CoreModel::InlineElement.new(
              format_type: 'link',
              target: href,
              content: content_str.strip,
              metadata: {
                title: (title.strip unless title.to_s.strip.empty?),
                right_constrain: right_constrain
              }.compact
            )
            out << link

            # Return single element or array
            out.length == 1 ? out.first : out
          end
        end

        register :a, A.new
      end
    end
  end
end
