# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      # HTML to CoreModel converter
      #
      # This class handles the conversion of HTML documents to CoreModel.
      # It does NOT handle serialization to any specific output format.
      # For serialization, use Coradoc.serialize(coremodel, to: :format)
      #
      # @example Basic usage - get CoreModel
      #   coremodel = HtmlConverter.to_core_model(html_string)
      #
      # @example Serialize to AsciiDoc
      #   coremodel = HtmlConverter.to_core_model(html_string)
      #   adoc_text = Coradoc.serialize(coremodel, to: :asciidoc)
      #
      class HtmlConverter
        # Convert HTML to CoreModel
        #
        # @param input [String, Nokogiri::XML::Document, Nokogiri::XML::Node] HTML input
        # @param options [Hash] Conversion options
        # @return [Coradoc::CoreModel::Base] CoreModel document
        def self.to_core_model(input, options = {})
          Input::Html.config.with(options) do
            plugin_instances = prepare_plugin_instances(options)

            root = track_time 'Loading input HTML document' do
              case input
              when String
                Nokogiri::HTML(input).root
              when Nokogiri::XML::Document
                input.root
              when Nokogiri::XML::Node
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

        def self.prepare_plugin_instances(options)
          options[:plugin_instances] || Html.config.plugins.map(&:new)
        end

        @track_time_indentation = 0
        def self.track_time(task)
          if Input::Html.config.track_time
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
end
