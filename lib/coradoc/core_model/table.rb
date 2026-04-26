# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Represents a table cell in a document
    #
    # Table cells can contain text content and have various formatting
    # attributes like alignment, colspan, rowspan, and styling.
    #
    # Cell format specification: [colspan][.rowspan][halign][valign][style][*]
    #
    # @example Creating a table cell with full formatting
    #   cell = CoreModel::TableCell.new(
    #     content: "Cell content",
    #     alignment: "center",
    #     colspan: 2,
    #     rowspan: 3,
    #     style: "emphasis",
    #     bgcolor: "#ffff00"
    #   )
    class TableCell < Base
      include ChildrenContent

      # @!attribute content
      #   @return [String, nil] text content of the cell
      attribute :content, :string

      # @!attribute alignment
      #   @return [String, nil] horizontal text alignment ('left', 'center', 'right')
      attribute :alignment, :string

      # @!attribute vertical_alignment
      #   @return [String, nil] vertical alignment ('top', 'middle', 'bottom')
      attribute :vertical_alignment, :string

      # @!attribute colspan
      #   @return [Integer, nil] number of columns to span
      attribute :colspan, :integer

      # @!attribute rowspan
      #   @return [Integer, nil] number of rows to span
      attribute :rowspan, :integer

      # @!attribute header
      #   @return [Boolean] whether this is a header cell
      attribute :header, :boolean, default: -> { false }

      # @!attribute style
      #   @return [String, nil] cell style ('default', 'strong', 'emphasis', 'monospace',
      #     'asciidoc', 'literal', 'verse')
      attribute :style, :string

      # @!attribute bgcolor
      #   @return [String, nil] background color (CSS color value)
      #   @note Populated by HTML converter only
      attribute :bgcolor, :string

      # @!attribute color
      #   @return [String, nil] text color (CSS color value)
      #   @note Populated by HTML converter only
      attribute :color, :string

      # @!attribute width
      #   @return [String, nil] cell width (CSS width value)
      #   @note Populated by HTML converter only
      attribute :width, :string

      # @!attribute height
      #   @return [String, nil] cell height (CSS height value)
      #   @note Populated by HTML converter only
      attribute :height, :string

      # Mixed content (strings and InlineElement objects)
      # @return [Array] mixed content array (via ChildrenContent)

      private

      def comparable_attributes
        %i[content alignment vertical_alignment colspan rowspan header style bgcolor color width height]
      end
    end

    # Represents a row in a table
    #
    # A table row contains multiple cells and can be a header row
    # or a data row.
    #
    # @example Creating a table row
    #   row = CoreModel::TableRow.new(
    #     cells: [
    #       CoreModel::TableCell.new(content: "Name"),
    #       CoreModel::TableCell.new(content: "Value")
    #     ],
    #     header: true
    #   )
    class TableRow < Base
      # @!attribute cells
      #   @return [Array<TableCell>] collection of cells in the row
      attribute :cells, TableCell, collection: true

      # @!attribute header
      #   @return [Boolean] whether this is a header row
      attribute :header, :boolean, default: -> { false }

      private

      def comparable_attributes
        %i[cells header]
      end
    end

    # Represents a table in a document
    #
    # Tables contain rows of cells and support various formatting options
    # like frame, grid, column widths, and styling.
    #
    # @example Creating a simple table
    #   table = CoreModel::Table.new(
    #     title: "Data Table",
    #     rows: [
    #       CoreModel::TableRow.new(
    #         cells: [
    #           CoreModel::TableCell.new(content: "Header 1", header: true),
    #           CoreModel::TableCell.new(content: "Header 2", header: true)
    #         ],
    #         header: true
    #       ),
    #       CoreModel::TableRow.new(
    #         cells: [
    #           CoreModel::TableCell.new(content: "Cell 1"),
    #           CoreModel::TableCell.new(content: "Cell 2")
    #         ]
    #       )
    #     ]
    #   )
    #
    # @example Creating a table with column specifications
    #   table = CoreModel::Table.new(
    #     cols: ["1", "2", "3"],  # relative widths
    #     col_alignments: ["left", "center", "right"],
    #     col_styles: [nil, "emphasis", "monospace"],
    #     rows: [...]
    #   )
    class Table < Base
      # @!attribute rows
      #   @return [Array<TableRow>] collection of table rows
      attribute :rows, TableRow, collection: true

      # @!attribute frame
      #   @return [String, nil] table frame style ('all', 'topbot', 'sides', 'none')
      #   @note Populated by HTML converter only
      attribute :frame, :string

      # @!attribute grid
      #   @return [String, nil] table grid style ('all', 'cols', 'rows', 'none')
      #   @note Not yet wired by any transformer; reserved for future use
      attribute :grid, :string

      # @!attribute width
      #   @return [String, nil] table width (e.g., '100%', '500px')
      attribute :width, :string

      # @!attribute cols
      #   @return [Array<String>, nil] column width specifications (e.g., ["1", "2", "3"])
      attribute :cols, :string, collection: true

      private

      def comparable_attributes
        super + %i[rows frame grid width cols]
      end
    end
  end
end
