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

    def process
      collapse_meaningless_sections
      generate_meaningful_sections
      # Do it again to simplify the document further.
      # Since the structure is changed, we may have new meaningful
      # sections as only children of some meaningless sections.
      collapse_meaningless_sections

      @tree
    end
  end
end
