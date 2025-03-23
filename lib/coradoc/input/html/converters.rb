module Coradoc
  module Input
    module Html
      module Converters
        def self.register(tag_name, converter)
          @@converters ||= {}
          @@converters[tag_name.to_sym] = converter
        end

        def self.unregister(tag_name)
          @@converters.delete(tag_name.to_sym)
        end

        def self.lookup(tag_name)
          converter = @@converters[tag_name.to_sym] || default_converter(tag_name)
          converter = converter.new if converter.respond_to? :new
          converter
        end

        # Note: process won't run plugin hooks
        def self.process(node, state)
          node = node.to_a if node.is_a? Nokogiri::XML::NodeSet
          return node.map { |i| process(i, state) }.join if node.is_a? Array

          lookup(node.name).convert(node, state)
        end

        def self.process_coradoc(node, state)
          node = node.to_a if node.is_a? Nokogiri::XML::NodeSet
          return node.map { |i| process_coradoc(i, state) } if node.is_a? Array

          plugins = state[:plugin_instances] || {}
          process = proc { lookup(node.name).to_coradoc(node, state) }
          plugins.each do |i|
            prev_process = process
            process = proc { i.html_tree_run_hooks(node, state, &prev_process) }
          end
          process.(node, state)
        end

        def self.default_converter(tag_name)
          case Coradoc::Input::Html.config.unknown_tags.to_sym
          when :pass_through
            Coradoc::Input::Html::Converters::PassThrough.new
          when :drop
            Coradoc::Input::Html::Converters::Drop.new
          when :bypass
            Coradoc::Input::Html::Converters::Bypass.new
          when :raise
            raise UnknownTagError, "unknown tag: #{tag_name}"
          else
            raise InvalidConfigurationError,
                  "unknown value #{Coradoc::Input::Html.config.unknown_tags.inspect} for Coradoc::Input::HTML.config.unknown_tags"
          end
        end
      end
    end
  end
end
