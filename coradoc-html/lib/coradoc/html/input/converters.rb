# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        # Autoload converter classes - they will register themselves when first accessed
        autoload :Base, 'coradoc/html/input/converters/base'
        autoload :Markup, 'coradoc/html/input/converters/markup'
        autoload :A, 'coradoc/html/input/converters/a'
        autoload :Aside, 'coradoc/html/input/converters/aside'
        autoload :Audio, 'coradoc/html/input/converters/audio'
        autoload :Blockquote, 'coradoc/html/input/converters/blockquote'
        autoload :Br, 'coradoc/html/input/converters/br'
        autoload :Bypass, 'coradoc/html/input/converters/bypass'
        autoload :Code, 'coradoc/html/input/converters/code'
        autoload :Div, 'coradoc/html/input/converters/div'
        autoload :Dl, 'coradoc/html/input/converters/dl'
        autoload :Skip, 'coradoc/html/input/converters/drop'
        autoload :Em, 'coradoc/html/input/converters/em'
        autoload :Figure, 'coradoc/html/input/converters/figure'
        autoload :H, 'coradoc/html/input/converters/h'
        autoload :Head, 'coradoc/html/input/converters/head'
        autoload :Hr, 'coradoc/html/input/converters/hr'
        autoload :Img, 'coradoc/html/input/converters/img'
        autoload :Li, 'coradoc/html/input/converters/li'
        autoload :Mark, 'coradoc/html/input/converters/mark'
        autoload :Math, 'coradoc/html/input/converters/math'
        autoload :MediaBase, 'coradoc/html/input/converters/media_base'
        autoload :Ol, 'coradoc/html/input/converters/ol'
        autoload :P, 'coradoc/html/input/converters/p'
        autoload :PassThrough, 'coradoc/html/input/converters/pass_through'
        autoload :PositionalFormatting, 'coradoc/html/input/converters/positional_formatting'
        autoload :Pre, 'coradoc/html/input/converters/pre'
        autoload :Q, 'coradoc/html/input/converters/q'
        autoload :Strong, 'coradoc/html/input/converters/strong'
        autoload :Sup, 'coradoc/html/input/converters/sup'
        autoload :Sub, 'coradoc/html/input/converters/sub'
        autoload :Table, 'coradoc/html/input/converters/table'
        autoload :Td, 'coradoc/html/input/converters/td'
        autoload :Text, 'coradoc/html/input/converters/text'
        autoload :Tr, 'coradoc/html/input/converters/tr'
        autoload :Video, 'coradoc/html/input/converters/video'

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

          [
            Base, Markup, A, Aside, Audio, Blockquote, Br, Bypass, Code, Div, Dl,
            Skip, Em, Figure, H, Head, Hr, Img, Li, Mark, Math, Ol, P,
            PassThrough, Pre, Q, Strong, Sup, Sub, Table, Td, Text, Tr, Video
          ].each { |converter| _ = converter }
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
