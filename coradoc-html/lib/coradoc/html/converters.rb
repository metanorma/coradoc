# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      CONVERTERS = {
        Base: 'coradoc/html/converters/base',
        Markup: 'coradoc/html/converters/markup',
        A: 'coradoc/html/converters/a',
        Aside: 'coradoc/html/converters/aside',
        Audio: 'coradoc/html/converters/audio',
        Blockquote: 'coradoc/html/converters/blockquote',
        Br: 'coradoc/html/converters/br',
        Bypass: 'coradoc/html/converters/bypass',
        Code: 'coradoc/html/converters/code',
        Div: 'coradoc/html/converters/div',
        Dl: 'coradoc/html/converters/dl',
        Skip: 'coradoc/html/converters/drop',
        Em: 'coradoc/html/converters/em',
        Figure: 'coradoc/html/converters/figure',
        H: 'coradoc/html/converters/h',
        Head: 'coradoc/html/converters/head',
        Hr: 'coradoc/html/converters/hr',
        Img: 'coradoc/html/converters/img',
        Li: 'coradoc/html/converters/li',
        Mark: 'coradoc/html/converters/mark',
        Math: 'coradoc/html/converters/math',
        MediaBase: 'coradoc/html/converters/media_base',
        Ol: 'coradoc/html/converters/ol',
        P: 'coradoc/html/converters/p',
        PassThrough: 'coradoc/html/converters/pass_through',
        PositionalFormatting: 'coradoc/html/converters/positional_formatting',
        Pre: 'coradoc/html/converters/pre',
        Q: 'coradoc/html/converters/q',
        Strong: 'coradoc/html/converters/strong',
        Sup: 'coradoc/html/converters/sup',
        Sub: 'coradoc/html/converters/sub',
        Table: 'coradoc/html/converters/table',
        Td: 'coradoc/html/converters/td',
        Text: 'coradoc/html/converters/text',
        Tr: 'coradoc/html/converters/tr',
        Video: 'coradoc/html/converters/video'
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
        case Html.input_config.unknown_tags.to_sym
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
                "unknown value #{Html.input_config.unknown_tags.inspect} " \
                  'for Coradoc::Html.input_config.unknown_tags'
        end
      end
    end
  end
end
