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
    option :asset_delivery, desc: 'Asset delivery mode (embedded, external)', type: :string, default: 'embedded'
    option :toc, desc: 'Include table of contents', type: :boolean, default: false
    option :toc_levels, desc: 'TOC depth (1-5)', type: :numeric, default: 2
    option :section_numbers, desc: 'Enable section numbering', type: :boolean, default: false
    option :section_number_levels, desc: 'Section numbering depth (1-6)', type: :numeric, default: 3
    option :lang, desc: 'Document language code', type: :string, default: 'en'
    option :resolve_includes, desc: 'Resolve include:: directives inline (default: leave as link nodes)',
           type: :boolean, default: false
    option :base_dir, desc: 'Base directory for include resolution (default: dirname of FILE)',
           type: :string
    option :missing_include, desc: 'Policy for missing includes: error, warn, silent, passthrough',
           type: :string, default: 'error'
    option :max_include_depth, desc: 'Maximum include nesting depth', type: :numeric,
           default: 64
    option :allow_unsafe_includes, desc: 'Disable path-traversal protection (asciidoctor :unsafe mode)',
           type: :boolean, default: false
    def convert(file)
      source_format = resolve_format(file, :from)
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

      doc = Coradoc.parse_file(file, format: source_format)
      doc = resolve_includes!(doc, file) if options[:resolve_includes]

      opts = build_convert_options
      result = Coradoc.serialize(doc, to: target_format, **opts)
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
      source_format = resolve_format(file)
      unless source_format
        error 'Error: Could not determine format. Use --format option.'
        exit 1
      end

      verbose_log "Validating #{file} (#{source_format})"

      result = Coradoc.validate_file(file, format: source_format)

      if result.valid?
        puts '✓ Document is valid'
      else
        error "✗ #{result}"
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
      source_format = resolve_format(file)
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
      source_format = resolve_format(file)
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

    def resolve_format(file, option_key = :format)
      raw = options[option_key]
      raw ? Coradoc.normalize_format(raw) : Coradoc.detect_format(file)
    end

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

    CONVERT_OPTIONS = %i[
      toc toc_levels section_numbers section_number_levels
      lang theme asset_delivery
    ].freeze
    private_constant :CONVERT_OPTIONS

    SYMBOL_OPTIONS = %i[theme asset_delivery].freeze
    private_constant :SYMBOL_OPTIONS

    def build_convert_options
      CONVERT_OPTIONS.each_with_object({}) do |key, opts|
        value = options[key]
        next unless value

        opts[key] = SYMBOL_OPTIONS.include?(key) ? value.to_sym : value
      end
    end

    def resolve_includes!(doc, source_file)
      base_dir = options[:base_dir] || File.expand_path(File.dirname(source_file))
      verbose_log "Resolving includes against #{base_dir}"
      Coradoc.resolve_includes(
        doc,
        base_dir: base_dir,
        missing_include: options[:missing_include].to_sym,
        max_depth: options[:max_include_depth],
        allow_unsafe: options[:allow_unsafe_includes]
      )
    end
  end
end
