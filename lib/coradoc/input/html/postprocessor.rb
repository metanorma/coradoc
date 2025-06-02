module Coradoc
  module Input
    module Html
      # Postprocessor's aim is to convert a Coradoc tree from
      # a mess that has been created from HTML into a tree that
      # is compatible with what we would get out of Coradoc, if
      # it parsed it directly.
      class Postprocessor
        Element = Coradoc::Element

        def self.process(coradoc)
          new(coradoc).process
        end

        def initialize(coradoc)
          @tree = coradoc
        end

        # Extracts titles from lists. This happens in HTML files
        # generated from DOCX documents by LibreOffice.
        #
        # We are interested in a particular tree:
        # Element::List::Ordered items:
        #   Element::List::Ordered items: (any depth)
        #     Element::ListItem content:
        #       Element::Title
        #       (any number of other titles of the same scheme)
        #
        # This tree is flattened into:
        # Element::Title
        # Element::Title (any number of titles)
        def extract_titles_from_lists
          @tree = Element::Base.visit(@tree) { |elem, dir|
            next elem unless dir == :pre
            next elem unless elem.is_a?(Element::List::Ordered)
            next elem if elem.items.length != 1

            anchors = []
            anchors << elem.anchor if elem.anchor

            # Extract ListItem from any depth of List::Ordered
            processed = elem
            while processed.is_a?(Element::List::Ordered)
              if processed.items.length != 1
                backtrack = true
                break
              end
              anchors << processed.anchor if processed.anchor
              processed = processed.items.first
            end

            # Something went wrong? Anything not matching on the way?
            next elem if backtrack
            next elem unless processed.is_a?(Element::ListItem)

            anchors << processed.anchor if processed.anchor

            # Now we must have a title (or titles).
            titles = processed.content.flatten

            # Don't bother if there's no title in there.
            next elem unless titles.any?(Element::Title)

            # Ordered is another iteration for our cleanup.
            next elem unless titles.all? do |i|
              i.is_a?(Element::Title) || i.is_a?(Element::List::Ordered)
            end

            # We are done now.
            titles + anchors
          }
        end

        # Collapse DIVs that only have a title, or nest another DIV.
        def collapse_meaningless_sections
          @tree = Element::Base.visit(@tree) { |elem, _dir|
            if elem.is_a?(Element::Section) && elem.safe_to_collapse?
              children_classes = Array(elem.contents).map(&:class)
              count = children_classes.length
              safe_classes = [Element::Section, Element::Title]

              # Count > 0 because some documents use <div> as a <br>.
              if count.positive? && children_classes.all? do |i|
                safe_classes.include?(i)
              end
                contents = elem.contents.dup
                contents.prepend(elem.anchor) if elem.anchor
                next contents
              end
            end
            elem
          }
        end

        # tree should now be more cleaned up, so we can progress with
        # creating meaningful sections
        def generate_meaningful_sections
          @tree = Element::Base.visit(@tree) { |elem, dir|
            # We are searching for an array, that has a title. This
            # will be a candidate for our section array.
            if dir == :post &&
                elem.is_a?(Array) &&
                !elem.flatten.grep(Element::Title).empty?

              elem = elem.flatten

              new_array = []
              content_array = new_array
              section_arrays_by_level = [new_array] * 8

              # For each title element, we create a new section. Then we push
              # all descendant sections into those sections. Otherwise, we push
              # an element as content of current section.
              elem.each do |e|
                if e.is_a? Element::Title
                  title = e
                  content_array = []
                  section_array = []
                  level = title.level_int
                  section = Element::Section.new(
                    title:, contents: content_array, sections: section_array,
                  )
                  # Some documents may not be consistent and eg. follow H4 after
                  # H2. Let's ensure that proceeding sections will land in a
                  # correct place.
                  (8 - level).times do |j|
                    section_arrays_by_level[level + j] = section_array
                  end
                  section_arrays_by_level[level - 1] << section
                else
                  content_array << e
                end
              end
              next new_array
            end
            elem
          }
        end

        def split_sections
          max_level = Coradoc::Input::Html.config.split_sections

          return unless max_level

          sections = {}
          parent_sections = []
          previous_sections = {}

          determine_section_id = ->(elem) do
            level = if elem.title.style == "appendix"
                      "A"
                    else
                      1
                    end

            section = previous_sections[elem]
            while section
              level = level.succ if elem.title.style == section.title.style
              section = previous_sections[section]
            end
            level.is_a?(Integer) ? "%02d" % level : level
          end

          determine_style = ->(elem) do
            style = elem.title.style || "section"
            style += "-"
            style
          end

          @tree = Element::Base.visit(@tree) { |elem, dir|
            title = elem.title if elem.is_a?(Element::Section)

            if title && title.level_int <= max_level
              if dir == :pre
                # In the PRE pass, we build a tree of sections, so that
                # we can compute numbers
                previous_sections[elem] = parent_sections[title.level_int]
                parent_sections[title.level_int] = elem
                parent_sections[(title.level_int + 1)..nil] = nil

                elem
              else
                # In the POST pass, we replace the sections with their
                # include tag.
                section_file = "sections/"
                section_file += parent_sections[1..title.level_int].map { |parent|
                  determine_style.(parent) + determine_section_id.(parent)
                }.join("/")
                section_file += ".adoc"

                sections[section_file] = elem
                up = "../" * (title.level_int - 1)
                "\ninclude::#{up}#{section_file}[]\n"
              end
            else
              elem
            end
          }

          sections[nil] = @tree
          @tree = sections
        end

        def process
          extract_titles_from_lists
          collapse_meaningless_sections
          generate_meaningful_sections
          # Do it again to simplify the document further.
          # Since the structure is changed, we may have new meaningful
          # sections as only children of some meaningless sections.
          collapse_meaningless_sections

          split_sections

          @tree
        end
      end
    end
  end
end
