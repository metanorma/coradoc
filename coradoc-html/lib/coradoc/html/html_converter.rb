# frozen_string_literal: true

module Coradoc
  module Html
    class HtmlConverter
      def self.to_core_model(input, options = {})
        Html.input_config.with(options) do
          plugin_instances = prepare_plugin_instances(options)

          root = track_time 'Loading input HTML document' do
            case input
            when String
              next nil if input.strip.empty?

              html_parse(input).root
            when Leptris::XML::Document
              input.root
            when Leptris::XML::Node
              input
            end
          end

          return nil unless root

          plugin_instances.each do |plugin|
            plugin.html_tree = root
            track_time "Preprocessing document with #{plugin.name} plugin" do
              plugin.preprocess_html_tree
            end
            root = plugin.html_tree
          end

          coremodel = track_time 'Converting input document tree to CoreModel' do
            Converters.process_coradoc(
              root,
              plugin_instances: plugin_instances
            )
          end

          coremodel = track_time 'Post-process CoreModel tree' do
            Postprocessor.process(coremodel)
          end

          coremodel = track_time 'Normalize top-level structure' do
            normalize_top_level(coremodel)
          end

          plugin_instances.each do |plugin|
            plugin.coremodel_tree = coremodel
            track_time "Postprocessing CoreModel tree with #{plugin.name} plugin" do
              plugin.postprocess_coremodel_tree
            end
            coremodel = plugin.coremodel_tree
          end

          options[:plugin_instances] = plugin_instances unless options.frozen?

          coremodel
        end
      end

      # #88/#102/#103: bare body-level text keeps HTML source
      # whitespace (trim its edges), and section ids must be
      # non-blank and unique document-wide (no empty or duplicated
      # [[anchor]]s in the output).
      def self.normalize_top_level(coremodel)
        seen_ids = {}
        normalized = normalize_children(Array(coremodel), seen_ids)
        coremodel.is_a?(Array) ? normalized : normalized.first
      end

      def self.normalize_children(children, seen_ids)
        children.filter_map do |child|
          case child
          when Coradoc::CoreModel::TextElement
            trimmed = child.content.to_s.gsub(/\A[ \t\r\n]+/, '')
                           .gsub(/[ \t\r\n]+\z/, '')
            next nil if trimmed.empty?

            child.content = trimmed
          when Coradoc::CoreModel::SectionElement
            normalize_section(child, seen_ids)
          end
          child
        end
      end

      # Renumbering replaces source-derived anchors (Word `_Toc…`,
      # `anchor-16`, …) with title-generated ids (#83).
      def self.renumber_anchors?
        Coradoc::Html.input_config.renumber_anchors
      end

      def self.normalize_section(section, seen_ids)
        id = renumber_anchors? ? '' : section.id.to_s.strip
        if id.empty?
          id = Coradoc::CoreModel::IdGenerator.generate_from_title(
            section.title
          ).to_s.sub(/\A_+/, '')
        end

        if id.empty?
          section.id = nil
        else
          original = id
          counter = 1
          while seen_ids.key?(id)
            id = "#{original}_#{counter}"
            counter += 1
          end
          section.id = id
          seen_ids[id] = true
        end

        nested = Array(section.children).select do |c|
          c.is_a?(Coradoc::CoreModel::SectionElement)
        end
        nested.each { |s| normalize_section(s, seen_ids) }
        section
      end

      def self.prepare_plugin_instances(options)
        options[:plugin_instances] || Html.input_config.plugins.map(&:new)
      end

      # Single dispatch point for the HTML parsing lane: :html4 keeps
      # Nokogiri::HTML byte-parity; :html5 selects the WHATWG-conformant
      # engine (implied tbody/tr, foster parenting, full implied head).
      # A synthesized empty <head/> is stripped before conversion — an
      # authored empty head (html4 lane, explicit markup) still produces
      # a DocumentElement with the placeholder title.
      def self.html_parse(input)
        if Html.input_config.html_version == :html5
          doc = Leptris::HTML5.parse(input)
          head = doc.at_css('head')
          head.parent&.remove_child(head) if head && head.children.empty?
          doc
        else
          Leptris::HTML.parse(input)
        end
      end

      @track_time_indentation = 0
      def self.track_time(task)
        if Html.input_config.track_time
          warn ('  ' * @track_time_indentation) + "* #{task} is starting..."
          @track_time_indentation += 1
          t0 = Time.now
          ret = yield
          time_elapsed = Time.now - t0
          @track_time_indentation -= 1
          warn ('  ' * @track_time_indentation) +
               "* #{task} took #{time_elapsed.round(3)} seconds"
          ret
        else
          yield
        end
      end
    end
  end
end
