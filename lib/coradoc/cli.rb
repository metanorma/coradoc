# frozen_string_literal: true

require 'thor'

module Coradoc
  class CLI < Thor
    package_name 'Coradoc'

    def self.exit_on_failure?
      true
    end

    desc 'convert FILE', 'Convert a document from one format to another'
    option :to, aliases: '-t', desc: 'Target format (adoc, html, md)', type: :string
    option :output, aliases: '-o', desc: 'Output file path (default: stdout)', type: :string
    option :from, aliases: '-f', desc: 'Source format (auto-detected from extension)', type: :string
    option :theme, desc: 'HTML theme (classic, modern)', type: :string, default: 'classic'
    option :verbose, desc: 'Enable verbose output', type: :boolean, default: false
    option :"asset-delivery", desc: 'Asset delivery mode (embedded, external)', type: :string, default: 'embedded'
    def convert(file)
      source_format = options[:from] ? Coradoc.normalize_format(options[:from]) : Coradoc.detect_format(file)
      target_format = options[:to] ? Coradoc.normalize_format(options[:to]) : Coradoc.resolve_output_format(options[:output])

      unless source_format && target_format
        error 'Error: Could not determine format. Use --from and --to options.'
        exit 1
      end

      unless Coradoc.serialize_format?(target_format)
        error "Error: Converting to #{target_format} is not yet supported."
        exit 1
      end

      verbose_log "Converting #{file} (#{source_format}) to #{target_format}"

      opts = {}
      opts[:theme] = options[:theme].to_sym if options[:theme]
      opts[:asset_delivery] = options[:"asset-delivery"].to_sym if options[:"asset-delivery"]

      result = Coradoc.convert_file(file, from: source_format, to: target_format, **opts)
      write_output(result, options[:output])
    rescue Coradoc::Error => e
      error "Error: #{e.message}"
      exit 1
    rescue StandardError => e
      error "Error: #{e.message}"
      verbose_log e.backtrace.join("\n") if options[:verbose]
      exit 1
    end

    desc 'formats', 'List supported formats'
    def formats
      caps = Coradoc.format_capabilities

      puts 'Supported formats:'
      puts ''
      puts '  Source formats (can read):'
      caps.each { |name, c| puts "    - #{name}" if c[:parse] }
      puts ''
      puts '  Target formats (can write):'
      caps.each { |name, c| puts "    - #{name}" if c[:serialize] }
    end

    desc 'version', 'Display Coradoc version'
    def version
      puts "Coradoc #{Coradoc::VERSION}"
    end

    desc 'validate FILE', 'Validate a document against its schema'
    option :format, aliases: '-f', desc: 'Source format (auto-detected from extension)', type: :string
    option :strict, desc: 'Enable strict validation mode', type: :boolean, default: false
    def validate(file)
      source_format = options[:format] ? Coradoc.normalize_format(options[:format]) : Coradoc.detect_format(file)
      unless source_format
        error 'Error: Could not determine format. Use --format option.'
        exit 1
      end

      verbose_log "Validating #{file} (#{source_format})"

      result = Coradoc.validate_file(file, format: source_format)

      if result.valid?
        puts '✓ Document is valid'
      else
        error '✗ Document has validation errors:'
        result.errors.each { |err| error "  - #{err.path}: #{err.message}" }
        exit 1
      end
    rescue Coradoc::Error => e
      error "Error: #{e.message}"
      exit 1
    rescue StandardError => e
      error "Error: #{e.message}"
      verbose_log e.backtrace.join("\n") if options[:verbose]
      exit 1
    end

    desc 'query FILE SELECTOR', 'Query document elements using CSS-like selectors'
    option :format, aliases: '-f', desc: 'Source format (auto-detected from extension)', type: :string
    option :output, aliases: '-o', desc: 'Output format (text, json)', type: :string, default: 'text'
    def query(file, selector)
      source_format = options[:format] ? Coradoc.normalize_format(options[:format]) : Coradoc.detect_format(file)
      unless source_format
        error 'Error: Could not determine format. Use --format option.'
        exit 1
      end

      verbose_log "Querying #{file} with selector: #{selector}"

      doc = Coradoc.parse_file(file, format: source_format)
      results = Coradoc::Query.query(doc, selector)

      if results.empty?
        puts "No elements found matching: #{selector}"
      else
        case options[:output]
        when 'json'
          require 'json'
          puts JSON.pretty_generate(results.map { |r| Coradoc.describe_element(r) })
        else
          puts "Found #{results.length} element(s):"
          results.each_with_index do |elem, i|
            puts "  #{i + 1}. #{Coradoc.describe_element(elem)}"
          end
        end
      end
    rescue Coradoc::Error => e
      error "Error: #{e.message}"
      exit 1
    rescue StandardError => e
      error "Error: #{e.message}"
      verbose_log e.backtrace.join("\n") if options[:verbose]
      exit 1
    end

    desc 'info FILE', 'Display document metadata and statistics'
    option :format, aliases: '-f', desc: 'Source format (auto-detected from extension)', type: :string
    def info(file)
      source_format = options[:format] ? Coradoc.normalize_format(options[:format]) : Coradoc.detect_format(file)
      unless source_format
        error 'Error: Could not determine format. Use --format option.'
        exit 1
      end

      verbose_log "Analyzing #{file} (#{source_format})"

      doc = Coradoc.parse_file(file, format: source_format)
      stats = Coradoc.document_stats(doc)
      fi = Coradoc.file_info(file)

      puts 'Document Information'
      puts '=' * 40
      puts "Format: #{source_format}"
      puts "File size: #{fi[:size]} bytes"
      puts "Line count: #{fi[:lines]}" if fi[:lines]
      puts "Title: #{stats[:title]}" if stats[:title]
      puts "Child elements: #{stats[:child_count]}" if stats[:child_count]

      if stats[:element_counts]&.any?
        puts ''
        puts 'Element Counts:'
        stats[:element_counts].each { |type, count| puts "  #{type}: #{count}" }
      end
    rescue Coradoc::Error => e
      error "Error: #{e.message}"
      exit 1
    rescue StandardError => e
      error "Error: #{e.message}"
      verbose_log e.backtrace.join("\n") if options[:verbose]
      exit 1
    end

    map '-v' => :version, '--version' => :version

    private

    def write_output(content, output_file)
      if output_file
        File.write(output_file, content)
        verbose_log "Written to: #{output_file}"
      else
        puts content
      end
    end

    def verbose_log(message)
      warn "[verbose] #{message}" if options[:verbose]
    end

    def error(message)
      warn message
    end
  end
end
