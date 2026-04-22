# frozen_string_literal: true

require 'thor'

module Coradoc
  # Command-line interface for Coradoc document conversions
  #
  # Provides commands for converting documents between different formats
  # (AsciiDoc, HTML, Markdown) using the hub-and-spoke architecture.
  #
  # @example Convert AsciiDoc to HTML
  #   coradoc convert document.adoc -o output.html
  #
  # @example Convert Markdown to HTML with custom options
  #   coradoc convert document.md -o output.html --theme modern
  #
  # @example Detect format automatically
  #   coradoc convert document.adoc --to html
  class CLI < Thor
    package_name 'Coradoc'

    # Map common shortcuts to format names
    FORMAT_ALIASES = {
      'adoc' => :asciidoc,
      'asciidoc' => :asciidoc,
      'docx' => :docx,
      'html' => :html,
      'md' => :markdown,
      'markdown' => :markdown
    }.freeze

    # Extension to format mapping for auto-detection
    EXTENSION_FORMATS = {
      '.adoc' => :asciidoc,
      '.asciidoc' => :asciidoc,
      '.docx' => :docx,
      '.html' => :html,
      '.htm' => :html,
      '.md' => :markdown,
      '.markdown' => :markdown,
      '.mdown' => :markdown
    }.freeze

    # Formats that require file path input (not text content)
    BINARY_FORMATS = %i[docx].freeze

    def self.exit_on_failure?
      true
    end

    desc 'convert FILE', 'Convert a document from one format to another'
    option :to, aliases: '-t', desc: 'Target format (adoc, html, md)', type: :string
    option :output, aliases: '-o', desc: 'Output file path (default: stdout)', type: :string
    option :from, aliases: '-f', desc: 'Source format (auto-detected from extension; supports docx, adoc, html, md)',
                  type: :string
    option :theme, desc: 'HTML theme (classic, modern)', type: :string, default: 'classic'
    option :verbose, desc: 'Enable verbose output', type: :boolean, default: false
    option :"asset-delivery", desc: 'Asset delivery mode (embedded, external)', type: :string, default: 'embedded'
    def convert(file)
      unless File.exist?(file)
        error "Error: File not found: #{file}"
        exit 1
      end

      source_format = detect_format(file, options[:from])
      target_format = normalize_format(options[:to]) || detect_output_format(options[:output])

      unless source_format && target_format
        error 'Error: Could not determine format. Use --from and --to options.'
        exit 1
      end

      # Reject unsupported target formats (e.g., docx is parse-only)
      target_mod = Coradoc.get_format(target_format)
      if target_mod.respond_to?(:serialize?) && !target_mod.serialize?
        error "Error: Converting to #{target_format} is not yet supported."
        exit 1
      end

      verbose_log "Converting #{file} (#{source_format}) to #{target_format}"

      if binary_format?(source_format)
        result = convert_binary(file, source_format, target_format, options)
      else
        content = File.read(file)
        result = convert_content(content, source_format, target_format, options)
      end

      write_output(result, options[:output])
    rescue NotImplementedError => e
      error "Error: #{e.message}"
      exit 1
    rescue Coradoc::UnsupportedFormatError => e
      error "Error: #{e.message}"
      exit 1
    rescue StandardError => e
      error "Error: #{e.message}"
      verbose_log e.backtrace.join("\n") if options[:verbose]
      exit 1
    end

    desc 'formats', 'List supported formats'
    def formats
      formats_info = Coradoc.registered_formats.map do |format|
        mod = Coradoc.get_format(format)
        {
          name: format,
          can_parse: mod.respond_to?(:parse_to_core) || mod.respond_to?(:parse),
          can_serialize: format_serialize?(mod)
        }
      end

      puts 'Supported formats:'
      puts ''
      puts '  Source formats (can read):'
      formats_info.select { |f| f[:can_parse] }.each do |f|
        puts "    - #{f[:name]}"
      end
      puts ''
      puts '  Target formats (can write):'
      formats_info.select { |f| f[:can_serialize] }.each do |f|
        puts "    - #{f[:name]}"
      end
    end

    desc 'version', 'Display Coradoc version'
    def version
      puts "Coradoc #{Coradoc::VERSION}"
    end

    desc 'validate FILE', 'Validate a document against its schema'
    option :format, aliases: '-f', desc: 'Source format (auto-detected from extension)', type: :string
    option :strict, desc: 'Enable strict validation mode', type: :boolean, default: false
    def validate(file)
      unless File.exist?(file)
        error "Error: File not found: #{file}"
        exit 1
      end

      source_format = detect_format(file, options[:format])
      unless source_format
        error 'Error: Could not determine format. Use --format option.'
        exit 1
      end

      verbose_log "Validating #{file} (#{source_format})"

      # Parse the document
      doc = parse_from_file(file, source_format)

      # Validate using the Validation framework
      if defined?(Coradoc::Validation::SchemaGenerator)
        schema = Coradoc::Validation::SchemaGenerator.generate(doc.class)
        if schema
          result = schema.validate(doc)
          if result.valid?
            puts '✓ Document is valid'
          else
            error '✗ Document has validation errors:'
            result.errors.each do |err|
              error "  - #{err.path}: #{err.message}"
            end
            exit 1
          end
        else
          puts '✓ Document parsed successfully (no schema generated)'
        end
      else
        puts '✓ Document parsed successfully'
      end
    rescue Coradoc::ParseError => e
      error "Parse error: #{e.message}"
      error "  Line #{e.line}, Column #{e.column}" if e.line
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
      unless File.exist?(file)
        error "Error: File not found: #{file}"
        exit 1
      end

      source_format = detect_format(file, options[:format])
      unless source_format
        error 'Error: Could not determine format. Use --format option.'
        exit 1
      end

      verbose_log "Querying #{file} with selector: #{selector}"

      # Parse the document
      doc = parse_from_file(file, source_format)

      # Query using the Query API
      results = Coradoc::Query.query(doc, selector)

      if results.empty?
        puts "No elements found matching: #{selector}"
      else
        case options[:output]
        when 'json'
          require 'json'
          puts JSON.pretty_generate(results.map { |r| describe_element(r) })
        else
          puts "Found #{results.length} element(s):"
          results.each_with_index do |elem, i|
            puts "  #{i + 1}. #{describe_element(elem)}"
          end
        end
      end
    rescue StandardError => e
      error "Error: #{e.message}"
      verbose_log e.backtrace.join("\n") if options[:verbose]
      exit 1
    end

    desc 'info FILE', 'Display document metadata and statistics'
    option :format, aliases: '-f', desc: 'Source format (auto-detected from extension)', type: :string
    def info(file)
      unless File.exist?(file)
        error "Error: File not found: #{file}"
        exit 1
      end

      source_format = detect_format(file, options[:format])
      unless source_format
        error 'Error: Could not determine format. Use --format option.'
        exit 1
      end

      verbose_log "Analyzing #{file} (#{source_format})"

      # Parse the document
      doc = parse_from_file(file, source_format)

      # Gather statistics
      puts 'Document Information'
      puts '=' * 40
      puts "Format: #{source_format}"
      puts "File size: #{File.size(file)} bytes"
      unless binary_format?(source_format)
        content = File.read(file)
        puts "Line count: #{content.lines.count}"
      end

      puts "Title: #{doc.title}" if doc.respond_to?(:title) && doc.title

      puts "Child elements: #{count_elements(doc)}" if doc.respond_to?(:children)

      # Count element types
      if defined?(Coradoc::Query)
        element_counts = count_element_types(doc)
        unless element_counts.empty?
          puts ''
          puts 'Element Counts:'
          element_counts.each do |type, count|
            puts "  #{type}: #{count}"
          end
        end
      end
    rescue StandardError => e
      error "Error: #{e.message}"
      verbose_log e.backtrace.join("\n") if options[:verbose]
      exit 1
    end

    map '-v' => :version, '--version' => :version

    private

    # Detect format from file extension or option
    def detect_format(file, format_option)
      return normalize_format(format_option) if format_option

      ext = File.extname(file).downcase
      EXTENSION_FORMATS[ext]
    end

    # Detect output format from output file extension
    def detect_output_format(output_file)
      return :html unless output_file

      ext = File.extname(output_file).downcase
      EXTENSION_FORMATS[ext] || :html
    end

    # Normalize format name (handle aliases)
    def normalize_format(format)
      return nil unless format

      FORMAT_ALIASES[format.to_s.downcase] || format.to_sym
    end

    # Get list of registered formats
    def registered_formats
      Coradoc.registered_formats
    end

    # Convert content between formats
    def convert_content(content, source_format, target_format, options)
      conversion_options = build_options(options, target_format)

      Coradoc.convert(
        content,
        from: source_format,
        to: target_format,
        **conversion_options
      )
    end

    # Build conversion options from CLI options
    def build_options(options, target_format)
      result = {}

      if target_format == :html
        result[:theme] = options[:theme].to_sym if options[:theme]
        result[:asset_delivery] = options[:"asset-delivery"].to_sym if options[:"asset-delivery"]
      end

      result
    end

    # Write output to file or stdout
    def write_output(content, output_file)
      if output_file
        File.write(output_file, content)
        verbose_log "Written to: #{output_file}"
      else
        puts content
      end
    end

    # Log message if verbose mode is enabled
    def verbose_log(message)
      warn "[verbose] #{message}" if options[:verbose]
    end

    # Print error message to stderr
    def error(message)
      warn message
    end

    # Describe an element for display
    def describe_element(elem)
      return elem.to_s unless elem.is_a?(Coradoc::CoreModel::Base)

      type = elem.class.name.split('::').last
      if elem.respond_to?(:title) && elem.title
        "#{type}: #{elem.title}"
      elsif elem.respond_to?(:content) && elem.content
        content_preview = elem.content.to_s[0..50]
        content_preview += '...' if elem.content.to_s.length > 50
        "#{type}: #{content_preview}"
      else
        type
      end
    end

    # Count total elements in a document
    def count_elements(doc)
      count = 0
      return count unless doc.respond_to?(:children)

      doc.children.each do |child|
        count += 1
        count += count_elements(child) if child.respond_to?(:children)
      end
      count
    end

    # Count elements by type
    def count_element_types(doc)
      counts = Hash.new(0)
      return counts unless defined?(Coradoc::Query)

      # Common element types to count
      types = %w[section paragraph block list_block table image inline_element]

      types.each do |type|
        results = Coradoc::Query.query(doc, type)
        counts[type] = results.length if results.length.positive?
      rescue StandardError
        # Skip types that can't be queried
      end

      counts
    end

    # Check if a format requires binary (file path) input
    def binary_format?(format)
      BINARY_FORMATS.include?(format)
    end

    # Parse a document from file, handling both text and binary formats
    def parse_from_file(file, source_format)
      if binary_format?(source_format)
        format_module = Coradoc.get_format(source_format)
        unless format_module.respond_to?(:parse_to_core)
          raise Coradoc::UnsupportedFormatError,
                "Format '#{source_format}' does not support parsing"
        end
        format_module.parse_to_core(file)
      else
        content = File.read(file)
        Coradoc.parse(content, format: source_format)
      end
    end

    # Convert from a binary format source
    def convert_binary(file_path, source_format, target_format, options)
      format_module = Coradoc.get_format(source_format)
      unless format_module
        raise Coradoc::UnsupportedFormatError,
              "Format '#{source_format}' is not registered. " \
              "Available formats: #{Coradoc.registered_formats.join(', ')}"
      end

      unless format_module.respond_to?(:parse_to_core)
        raise Coradoc::UnsupportedFormatError,
              "Format module #{format_module} does not implement parse_to_core"
      end

      verbose_log "Reading binary file: #{file_path}"
      core = format_module.parse_to_core(file_path)

      conversion_options = build_options(options, target_format)
      Coradoc.serialize(core, to: target_format, **conversion_options)
    end

    # Check if a format module supports serialization
    def format_serialize?(mod)
      return false unless mod.respond_to?(:serialize)
      return mod.serialize? if mod.respond_to?(:serialize?)

      true
    end
  end
end
