# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module Toc
        def self.call(element, context:)
          entries = if element.is_a?(CoreModel::Toc) && element.entries
                      Array(element.entries).filter_map do |entry|
                        build_entry(entry, context)
                      end
                    else
                      []
                    end

          Node::Toc.new(
            attrs: Node::Toc::Attrs.new(title: element.title),
            content: entries
          )
        end

        class << self
          private

          def build_entry(entry, context)
            children = if entry.is_a?(CoreModel::TocEntry) && entry.children
                         entry.children.filter_map { |c| build_entry(c, context) }
                       else
                         []
                       end

            content = [context.text_node(entry.title.to_s)] unless children.any?
            content ||= children

            Node::TocEntry.new(
              attrs: Node::TocEntry::Attrs.new(
                id: entry.is_a?(CoreModel::TocEntry) ? entry.id : nil,
                title: entry.is_a?(CoreModel::TocEntry) ? entry.title : nil,
                level: entry.is_a?(CoreModel::TocEntry) ? entry.level : nil
              ),
              content: content
            )
          end
        end
      end
    end
  end
end
