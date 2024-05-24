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

        cols = ensure_row_column_integrity_and_get_column_number(node)
        attrs.add_named("cols", "#{cols}*")

        # This line should be removed.
        return "" if attrs.empty?

        attrs
      end

      def ensure_row_column_integrity_and_get_column_number(node)
        rows = node.xpath(".//tr")
        num_rows = rows.length
        computed_columns_per_row = [0] * num_rows
        cell_references = [nil] * num_rows

        recompute = proc do
          return ensure_row_column_integrity_and_get_column_number(node)
        end

        rows.each_with_index do |row, i|
          columns = row.xpath("./td | ./th")
          columns.each do |cell|
            colspan = cell["colspan"]&.to_i || 1
            rowspan = cell["rowspan"]&.to_i || 1

            rowspan.times do |j|
              # Let's increase the table for particularly bad documents
              computed_columns_per_row[i + j] ||= 0
              computed_columns_per_row[i + j] += colspan

              cell_references[i + j] ||= []
              colspan.times do |k|
                cell_references[i + j] << [cell, k > 0]
              end
            end
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
            row_obj.add_child(Nokogiri::XML::Node.new("td", doc))

            modified = true
          end

          recompute.() if modified

          ### We should have a correct document now and we should never
          ### end up here.
        end

        computed_columns_per_row.first
      end
    end

    register :table, Table.new
  end
end
