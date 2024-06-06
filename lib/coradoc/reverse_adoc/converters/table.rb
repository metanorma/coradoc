module Coradoc::ReverseAdoc
  module Converters
    class Table < Base
      def to_coradoc(node, state = {})
        id = node["id"]
        title = extract_title(node)
        attrs = style(node)
        content = treat_children_coradoc(node, state)
        Coradoc::Element::Table.new(title, content, { id: id, attrs: attrs })
      end

      def extract_title(node)
        title = node.at("./caption")
        return "" if title.nil?

        treat_children(title, {})
      end

      def frame(node)
        case node["frame"]
        when "void"
          "none"
        when "hsides"
          "topbot"
        when "vsides"
          "sides"
        when "box", "border"
          "all"
        end
      end

      def rules(node)
        case node["rules"]
        when "all"
          "all"
        when "rows"
          "rows"
        when "cols"
          "cols"
        when "none"
          "none"
        end
      end

      def style(node)
        attrs = Coradoc::Element::AttributeList.new
        # Width is disabled on tables for now. (From #88)
        # attrs.add_named("width", node["width"]) if node["width"]

        frame_attr = frame(node)
        attrs.add_named("frame", frame_attr) if frame_attr

        rules_attr = rules(node)
        attrs.add_named("rules", rules_attr) if rules_attr

        # We can't, and shouldn't do those calculation if the table we are
        # processing is empty.
        unless empty?(node)
          cols = ensure_row_column_integrity_and_get_column_sizes(node)
          attrs.add_named("cols", cols)

          # Header first rows can't span multiple riws - drop header if they do.
          header = node.at_xpath(".//tr")
          unless header.xpath("./td | ./th").all? { |i| [nil, "1", ""].include? i["rowspan"] }
            attrs.add_named("options", ["noheader"])
          end
        end

        # This line should be removed.
        return "" if attrs.empty?

        attrs
      end

      def empty?(node)
        !node.at_xpath(".//td | .//th")
      end

      def ensure_row_column_integrity_and_get_column_sizes(node)
        rows = node.xpath(".//tr")
        num_rows = rows.length
        computed_columns_per_row = [0] * num_rows
        # Both those variables may seem the same, but they have a crucial
        # difference.
        #
        # cell_references don't necessarily contain an image of created
        # table. New cells are pushed to it as needed, so if we have a
        # one cell with colspan and rowspan of 2 on the previous row,
        # those will always be first in the row, regardless of their
        # position. This array is only used to warrant the table
        # integrity.
        #
        # cell_matrix, on the other hand, can't be constructed outright.
        # It will be incorrect as long as the table isn't fixed. So we
        # can't use it to correct colspans/rowspans/missing rows. Once
        # we have it constructed, only then we can calculate the correct
        # column widths.
        cell_references = [nil] * num_rows
        cell_matrix = [nil] * num_rows

        recompute = proc do
          return ensure_row_column_integrity_and_get_column_sizes(node)
        end

        fits_in_cell_matrix = proc do |y,x,rowspan,colspan|
          rowspan.times.all? do |yy|
            colspan.times.all? do |xx|
              !cell_matrix.dig(y+yy, x+xx)
            end
          end
        end

        rows.each_with_index do |row, i|
          columns = row.xpath("./td | ./th")
          column_id = 0

          columns.each do |cell|
            colspan = cell["colspan"]&.to_i || 1
            rowspan = cell["rowspan"]&.to_i || 1

            column_id += 1 until fits_in_cell_matrix.(i,column_id,rowspan,colspan)

            rowspan.times do |j|
              # Let's increase the table for particularly bad documents
              computed_columns_per_row[i + j] ||= 0
              computed_columns_per_row[i + j] += colspan

              cell_references[i + j] ||= []
              cell_matrix[i + j] ||= []
              colspan.times do |k|
                cell_references[i + j] << [cell, k > 0]
                cell_matrix[i + j][column_id] = cell
                column_id += 1
              end
              column_id -= colspan
            end
            column_id += colspan
          end
        end

        ##### Fixups
        cpr = computed_columns_per_row

        # Some cell has too high colspan
        if cpr.length > num_rows
          cell_references[num_rows].each do |cell,|
            next unless cell

            cell["rowspan"] = cell["rowspan"].to_i - 1
          end

          # Let's recompute the numbers
          recompute.()
        end

        if [cpr.first] * num_rows != cpr
          # Colspan inconsistencies
          modified = false
          cpr_max = cpr.max
          max_rows = cell_references.sort_by(&:length).reverse
          max_rows.each do |row|
            break if row.length != cpr_max

            cell, spanning = row.last

            if spanning
              modified = true
              cell["colspan"] = cell["colspan"].to_i - 1
            end
          end

          recompute.() if modified

          # We are out of colspans to fix. If we are at this point, this
          # means there is an inconsistent number of TH/TDs simply.
          # Here, the solution is to add empty TDs.
          min_rows = cell_references.sort_by(&:length)
          cpr_min = cpr.min
          min_rows.each do |row|
            break if row.length != cpr_min

            row_obj = row.last.first.parent
            doc = row_obj.document
            added_node = Nokogiri::XML::Node.new("td", doc)
            added_node["x-added"] = "x-added"
            row_obj.add_child(added_node)

            modified = true
          end

          recompute.() if modified

          ### We should have a correct document now and we should never
          ### end up here.
          warn "**** Couldn't fix table sizes for table on line #{node.line}"
        end

        # For column size computation, we must have an integral cell_matrix.
        # Let's verify that all columns and rows are populated.
        cell_matrix_correct = cell_matrix.length.times.all? do |y|
          cell_matrix[y].length.times.all? do |x|
            cell_matrix[y][x]
          end
        end

        unless cell_matrix_correct
          # It may be a special case that we need to add virtual cells at the
          # beginning not the end of a row.
          needs_recompute = false
          cell_matrix.each do |row|
            if row.compact.length != row.length
              last_cell = row.last
              if last_cell["x-added"]
                last_cell.parent.prepend_child(last_cell)
                needs_recompute = true
              end
            end
          end
          recompute.() if needs_recompute

          # But otherwise... we've got a really nasty table.
          warn <<~WARNING.gsub("\n", " ")
            **** Couldn't construct a valid image of a table on line
            #{node.line}. We need that to reliably compute column
            widths of that table. Please report a bug to metanorma/coradoc
            repository.
          WARNING
        end

        # Compute column sizes
        column_sizes = []
        cell_matrix.each do |row|
          row.each_with_index do |(cell,_), i|
            next unless !cell || [nil, "", "1"].include?(cell["colspan"])

            column_sizes[i] ||= []
            column_sizes[i] << cell["width"]
          end
        end

        document_width = Coradoc::ReverseAdoc.config.doc_width.to_r

        column_sizes += [nil] * (cpr.first - column_sizes.length)

        sizes = column_sizes.map do |col|
          col = [] if col.nil?

          max = col.map do |i|
            if i.nil?
              0r
            elsif i.end_with?("%")
              document_width * i.to_i / 100
            else
              i.to_r
            end
          end.max

          if max.nil? || max.negative?
            0r
          else
            max
          end
        end

        # The table seems bigger than the document... let's scale all
        # values.
        while sizes.map { |i|
                          i.zero? ? document_width / 3 / sizes.length : i
                        }.sum > document_width

          sizes = sizes.map { |i| i * 4 / 5 }
        end

        rest = document_width - sizes.sum
        unset = sizes.count(&:zero?)

        # Fill in zeros with remainder space
        sizes = sizes.map do |i|
          if i.zero?
            rest / unset
          else
            i
          end
        end

        # Scale to integers
        lcm = sizes.map(&:denominator).inject(1) { |i,j| i.lcm(j) }
        sizes = sizes.map { |i| i * lcm }.map(&:to_i)

        # Scale down by gcd
        gcd = sizes.inject(sizes.first) { |i,j| i.gcd(j) }
        sizes = sizes.map { |i| i / gcd }

        # Try to generate a shorter definition
        if [sizes.first] * sizes.length == sizes
          sizes.length
        else
          sizes.join(",")
        end
      end
    end

    register :table, Table.new
  end
end
