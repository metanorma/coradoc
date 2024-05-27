module Coradoc::ReverseAdoc
  # Postprocessor's aim is to convert a Coradoc tree from
  # a mess that has been created from HTML into a tree that
  # is compatible with what we would get out of Coradoc, if
  # it parsed it directly.
  class Postprocessor
    def self.process(coradoc)
      new(coradoc).process
    end

    def initialize(coradoc)
      @tree = coradoc
    end

    # Collapse DIVs that only have a title, or nest another DIV.
    def collapse_meaningless_sections
      @tree = Coradoc::Element::Base.visit(@tree) do |elem, _dir|
        if elem.is_a?(Coradoc::Element::Section) && elem.safe_to_collapse?
          children_classes = Array(elem.contents).map(&:class)
          count = children_classes.length
          safe_classes = [Coradoc::Element::Section, Coradoc::Element::Title]

          # Count > 0 because some documents use <div> as a <br>.
          if count > 0 && children_classes.all? { |i| safe_classes.include?(i) }
            next elem.contents
          end
        end
        elem
      end
    end

    # tree should now be more cleaned up, so we can progress with
    # creating meaningful sections
    def generate_meaningful_sections
      @tree = Coradoc::Element::Base.visit(@tree) do |elem, dir|
        # We are searching for an array, that has more than 2 elements and
        # one of those elements is a title. This will be a candidate for
        # our section array.
        if dir == :post &&
            elem.is_a?(Array) &&
            elem.length >= 2 &&
            !elem.grep(Coradoc::Element::Title).empty?

          new_array = []
          content_array = new_array
          section_arrays_by_level = [new_array] * 8

          # For each title element, we create a new section. Then we push
          # all descendant sections into those sections. Otherwise, we push
          # an element as content of current section.
          elem.each do |e|
            if e.is_a? Coradoc::Element::Title
              title = e
              content_array = []
              section_array = []
              level = title.level_int
              section = Coradoc::Element::Section.new(
                title, contents: content_array, sections: section_array
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
      end
    end

    def split_sections
      max_level = Coradoc::ReverseAdoc.config.split_sections

      return unless max_level

      sections = {}
      parent_sections = []
      previous_sections = {}

      determine_section_id = ->(elem) do
        level = 0
        section = elem
        while section
          level += 1 if elem.title.style == section.title.style
          section = previous_sections[section]
        end
        level
      end

      determine_style = ->(elem) do
        style = elem.title.style || "section"
        style += "-"
        style
      end

      @tree = Coradoc::Element::Base.visit(@tree) do |elem, dir|
        title = elem.title if elem.is_a?(Coradoc::Element::Section)

        if title && title.level_int <= max_level
          if dir == :pre
            # In the PRE pass, we build a tree of sections, so that
            # we can compute numbers
            previous_sections[elem] = parent_sections[title.level_int]
            parent_sections[title.level_int] = elem
            parent_sections[(title.level_int+1)..nil] = nil

            elem
          else
            # In the POST pass, we replace the sections with their
            # include tag.
            section_file = "sections/"
            section_file += parent_sections[1..title.level_int].map do |parent|
              style = determine_style.(parent)
              "%s%02d" % [style, determine_section_id.(parent)]
            end.join("/")
            section_file += ".adoc"

            sections[section_file] = elem
            up = "../" * (title.level_int - 1)
            "include::#{up}#{section_file}[]\n\n"
          end
        else
          elem
        end
      end

      sections[nil] = @tree
      @tree = sections
    end

    def process
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
