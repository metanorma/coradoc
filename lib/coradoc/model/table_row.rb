# frozen_string_literal: true

module Coradoc
  module Model
    class TableRow < Base
      attribute :columns, Coradoc::Model::TableCell, collection: true
      attribute :header, :boolean, default: -> { false }

      asciidoc do
        map_attribute "columns", to: :columns
      end

      def table_header_row?
        header
      end

      def asciidoc?
        columns&.any?(&:asciidoc?) || false
      end

      def to_asciidoc
        delim = asciidoc? ? "\n" : " "

        content = columns.map { |col|
          Coradoc::Generator.gen_adoc(col)
        }.join(delim)

        result = "#{content}\n"
        result << "\n" if asciidoc?
        if table_header_row?
          result + underline_for
        else
          result
        end
      end

      # XXX: Why is it called #underline_for ?
      def underline_for
        "\n"
      end
    end
  end
end
