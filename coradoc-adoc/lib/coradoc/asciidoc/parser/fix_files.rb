# frozen_string_literal: true

# Script to fix parser file structure

files = %w[attribute_list.rb bibliography.rb block.rb block_assembler.rb citation.rb
           content.rb document_attributes.rb header.rb inline.rb list.rb
           metadata_detector.rb paragraph.rb section.rb table.rb term.rb text.rb]

files.each do |filename|
  next unless File.exist?(filename)

  content = File.read(filename)
  lines = content.lines

  # The correct structure should be:
  # module Coradoc
  #   module AsciiDoc
  #     module Parser
  #       module SomeModule
  #         ...content...
  #       end
  #     end
  #   end
  # end

  # Count structure
  puts "=== #{filename} ==="

  # Find all lines that are just "end" with various indentation
  end_lines = lines.each_with_index.select { |line, _i| line.strip == 'end' }
  puts "Found #{end_lines.size} 'end' statements"

  # We should have exactly 4 'end' statements for the module nesting
  # (Coradoc, AsciiDoc, Parser, SomeModule)
  # But we might have a class inside which adds more

  # Let's just fix the pattern: if we have "  end" followed by "end" at the end,
  # the "  end" is extra

  new_lines = []
  i = 0
  while i < lines.size
    line = lines[i]

    # Check for the pattern: "    end" followed by "  end" followed by "end"
    if line == "    end\n" && i + 2 < lines.size &&
       lines[i + 1] == "  end\n" && lines[i + 2] == "end\n"
      # Keep the "    end", skip the extra "  end", keep "end"
      new_lines << line
      new_lines << lines[i + 2]
      i += 3
      next
    end

    # Check for pattern: "      end" followed by "    end" followed by "  end" followed by "end"
    if line == "      end\n" && i + 3 < lines.size &&
       lines[i + 1] == "    end\n" && lines[i + 2] == "  end\n" && lines[i + 3] == "end\n"
      # This is: end (class/module), end (Parser), end (AsciiDoc), end (Coradoc)
      # But we have an extra one - the correct should be:
      # end (inner module), end (Parser), end (AsciiDoc), end (Coradoc)
      # Let's see what's inside...
      new_lines << line
      new_lines << "    end\n"
      new_lines << "  end\n"
      new_lines << "end\n"
      i += 4
      next
    end

    new_lines << line
    i += 1
  end

  File.write(filename, new_lines.join)
  puts "Fixed: #{filename}"
end
