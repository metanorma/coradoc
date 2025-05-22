require "parslet"
require "parslet/convenience"

require_relative "admonition"
require_relative "attribute_list"
require_relative "bibliography"
require_relative "block"
require_relative "citation"
require_relative "content"
require_relative "document_attributes"
require_relative "header"
require_relative "inline"
require_relative "list"
require_relative "paragraph"
require_relative "section"
require_relative "table"
require_relative "term"
require_relative "text"

module Coradoc
  module Parser
    module Asciidoc
      class Base < Parslet::Parser
        include Coradoc::Parser::Asciidoc::Admonition
        include Coradoc::Parser::Asciidoc::AttributeList
        include Coradoc::Parser::Asciidoc::Bibliography
        include Coradoc::Parser::Asciidoc::Block
        include Coradoc::Parser::Asciidoc::Citation
        include Coradoc::Parser::Asciidoc::Content
        include Coradoc::Parser::Asciidoc::DocumentAttributes
        include Coradoc::Parser::Asciidoc::Header
        include Coradoc::Parser::Asciidoc::Inline
        include Coradoc::Parser::Asciidoc::List
        include Coradoc::Parser::Asciidoc::Paragraph
        include Coradoc::Parser::Asciidoc::Section
        include Coradoc::Parser::Asciidoc::Table
        include Coradoc::Parser::Asciidoc::Term
        include Coradoc::Parser::Asciidoc::Text

        def rule_dispatch(rule_name, *args, **kwargs)
          @dispatch_data ||= {}
          dispatch_key = [rule_name, args, kwargs.to_a.sort]
          dispatch_hash = dispatch_key.hash.abs
          unless @dispatch_data.has_key?(dispatch_hash)
            alias_name = "#{rule_name}_#{dispatch_hash}".to_sym
            Coradoc::Parser::Asciidoc::Base.class_exec do
              rule(alias_name) do
                send(rule_name, *args, **kwargs)
              end
            end
            @dispatch_data[dispatch_hash] = alias_name
          end
          dispatch_method = @dispatch_data[dispatch_hash]
          send(dispatch_method)
        end

        def self.config(key)
          # XXX: Where do these come from? Are these meant to be configurable?
          c = {
            add_dispatch: true,
            with_params: true,
          }

          if c.keys.include?(key)
            c[key]
          else
            raise ArgumentError, "Unknown config key: #{key}. Available keys: #{c.keys.join(", ")}"
          end
        end

        parser_methods = (Coradoc::Parser::Asciidoc.constants - [:Base]).reduce({}) do |acc, const|
          rule_names = Coradoc::Parser::Asciidoc.const_get(const).instance_methods
          rule_names.each do |rule_name|
            acc[rule_name] ||= []
            acc[rule_name] << const
          end
          acc
        end

        # Warn about duplicated parser methods:
        parser_methods.each do |rule_name, defn_sites|
          count = defn_sites.length
          if count > 1
            defn_site_constants = defn_sites.map { |const| Coradoc::Parser::Asciidoc.const_get(const) }
            Logger.warn "Parser method '#{rule_name}' is defined #{count} times in #{defn_site_constants.join(", ")}"
          end
        end

        parser_methods.keys.each do |rule_name|
          params = Coradoc::Parser::Asciidoc::Base.instance_method(rule_name).parameters
          if config(:add_dispatch) && params == []
            alias_name = :"alias_nondispatch_#{rule_name}"
            Coradoc::Parser::Asciidoc::Base.class_exec do
              alias_method alias_name, rule_name
              rule(rule_name) do
                send(alias_name)
              end
            end
          elsif config(:add_dispatch) && config(:with_params)
            alias_name = :"alias_dispatch_#{rule_name}"
            Coradoc::Parser::Asciidoc::Base.class_exec do
              alias_method alias_name, rule_name
              define_method(rule_name) do |*args, **kwargs|
                rule_dispatch(alias_name, *args, **kwargs)
              end
            end
          end
        end
      end
    end
  end
end
