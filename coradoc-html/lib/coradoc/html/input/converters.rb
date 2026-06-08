# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        # Autoload converter classes — they self-register when loaded.
        # Adding a new converter requires only adding one entry here.
        CONVERTERS = {
          Base: 'coradoc/html/input/converters/base',
          Markup: 'coradoc/html/input/converters/markup',
          A: 'coradoc/html/input/converters/a',
          Aside: 'coradoc/html/input/converters/aside',
          Audio: 'coradoc/html/input/converters/audio',
          Blockquote: 'coradoc/html/input/converters/blockquote',
          Br: 'coradoc/html/input/converters/br',
          Bypass: 'coradoc/html/input/converters/bypass',
          Code: 'coradoc/html/input/converters/code',
          Div: 'coradoc/html/input/converters/div',
          Dl: 'coradoc/html/input/converters/dl',
          Skip: 'coradoc/html/input/converters/drop',
          Em: 'coradoc/html/input/converters/em',
          Figure: 'coradoc/html/input/converters/figure',
          H: 'coradoc/html/input/converters/h',
          Head: 'coradoc/html/input/converters/head',
          Hr: 'coradoc/html/input/converters/hr',
          Img: 'coradoc/html/input/converters/img',
          Li: 'coradoc/html/input/converters/li',
          Mark: 'coradoc/html/input/converters/mark',
          Math: 'coradoc/html/input/converters/math',
          MediaBase: 'coradoc/html/input/converters/media_base',
          Ol: 'coradoc/html/input/converters/ol',
          P: 'coradoc/html/input/converters/p',
          PassThrough: 'coradoc/html/input/converters/pass_through',
          PositionalFormatting: 'coradoc/html/input/converters/positional_formatting',
          Pre: 'coradoc/html/input/converters/pre',
          Q: 'coradoc/html/input/converters/q',
          Strong: 'coradoc/html/input/converters/strong',
          Sup: 'coradoc/html/input/converters/sup',
          Sub: 'coradoc/html/input/converters/sub',
          Table: 'coradoc/html/input/converters/table',
          Td: 'coradoc/html/input/converters/td',
          Text: 'coradoc/html/input/converters/text',
          Tr: 'coradoc/html/input/converters/tr',
          Video: 'coradoc/html/input/converters/video'
        }.freeze
        private_constant :CONVERTERS

        CONVERTERS.each do |name, path|
          autoload name, path
        end

        @converters = {}
        @converters_loaded = false

        def self.register(tag_name, converter)
          @converters[tag_name.to_sym] = converter
        end

        def self.unregister(tag_name)
          @converters.delete(tag_name.to_sym)
        end

        def self.ensure_converters_loaded
          return if @converters_loaded

          @converters_loaded = true
          CONVERTERS.each_key { |name| const_get(name) }
        end

        def self.lookup(tag_name)
          ensure_converters_loaded
          @converters[tag_name.to_sym] || default_converter(tag_name)
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
          process.call(node, state)
        end

        def self.default_converter(tag_name)
          case Html.config.unknown_tags.to_sym
          when :pass_through
            PassThrough::INSTANCE
          when :drop
            Skip::INSTANCE
          when :bypass
            Bypass::INSTANCE
          when :raise
            raise Errors::UnknownTagError, "unknown tag: #{tag_name}"
          else
            raise Errors::InvalidConfigurationError,
                  "unknown value #{Html.config.unknown_tags.inspect} for Coradoc::Input::Html.config.unknown_tags"
          end
        end
      end
    end
  end
end
