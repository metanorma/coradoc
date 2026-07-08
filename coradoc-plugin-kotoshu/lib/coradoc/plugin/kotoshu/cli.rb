# frozen_string_literal: true

require 'thor'

module Coradoc
  module Plugin
    module Kotoshu
      # Thor-based CLI for the plugin.
      #
      # Usage:
      #   coradoc-kotoshu check README.adoc --language en --format yaml
      class Cli < Thor
        class Error < StandardError; end
        class MissingInput < Error; end
        class InvalidFormat < Error; end

        FORMATS = %w[yaml json].freeze

        desc 'check FILE', 'Spell-check an AsciiDoc file and emit a YAML/JSON report'
        option :language, aliases: '-l', default: 'en', type: :string,
                          desc: 'BCP-47 language code (e.g. en, en-US, de)'
        option :format, aliases: '-f', default: 'yaml', type: :string,
                        desc: 'Report format: yaml or json'
        option :output, aliases: '-o', type: :string,
                        desc: 'Write the report to this path (defaults to stdout)'
        option :spellchecker, aliases: '-s', type: :string, banner: 'DICTIONARY',
                              desc: 'Path to a plain-text dictionary file. Overrides --language.'
        option :verbose, type: :boolean, default: false,
                         desc: 'Print progress to stderr'
        def check(file)
          raise MissingInput, 'no input file provided' if file.nil? || file.empty?

          unless FORMATS.include?(options[:format])
            raise InvalidFormat,
                  "unknown format #{options[:format].inspect} (use: #{FORMATS.join(', ')})"
          end
          raise MissingInput, "file not found: #{file}" unless File.exist?(file)

          checker = build_checker
          warn "Parsing #{file}..." if options[:verbose]
          report = checker.check_file(file)
          warn "Checked #{report.word_count} word(s); found #{report.error_count} misspelling(s)." if options[:verbose]

          output = render(report, options[:format])
          write_output(output, options[:output])
        rescue ::Kotoshu::ResourceNotSetupError, ::Kotoshu::Errors::Base => e
          raise Error, "kotoshu: #{e.message}"
        end

        desc 'version', 'Print the plugin version'
        def version
          puts "coradoc-plugin-kotoshu #{VERSION}"
        end
        map '--version' => :version, '-v' => :version

        private

        def build_checker
          if options[:spellchecker]
            require 'kotoshu'
            dict = ::Kotoshu::Dictionary::PlainText.new(
              options[:spellchecker],
              language_code: options[:language]
            )
            sc = ::Kotoshu::Spellchecker.new(dictionary: dict)
            Checker.new(spellchecker: sc, language: options[:language])
          else
            Checker.new(language: options[:language])
          end
        end

        def render(report, format)
          case format
          when 'yaml' then report.to_yaml
          when 'json' then JSON.pretty_generate(JSON.parse(report.to_json))
          end
        end

        def write_output(text, output_path)
          if output_path
            File.write(output_path, text)
            warn "Wrote #{output_path}" if options[:verbose]
          else
            puts text
          end
        end
      end
    end
  end
end
