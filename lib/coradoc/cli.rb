require "coradoc"
require "thor"

module Coradoc
  class CLI < Thor
    package_name "coradoc"

    desc "convert [FILE]", "Convert document to another format"

    option :output,
           type: :string, aliases: "-o",
           desc: "Output file to write"

    option :input_format,
           type: :string, aliases: "-I",
           enum: Input.keys.map(&:to_s), default: nil,
           desc: "Define input format (defaults to input file extension)"

    option :output_format,
           type: :string, aliases: "-O",
           enum: Output.keys.map(&:to_s), default: nil,
           desc: "Define output format (defaults to output file extension)"

    at_least_one :output, :output_format

    option :require,
           type: :string, aliases: "-r",
           repeatable: true,
           desc: "Require additional Ruby file (eg. to load a plugin)"

    option :external_images,
           type: :boolean, aliases: "-e",
           desc: "Extract images from input document"

    option :unknown_tags,
           type: :string, aliases: "-u",
           enum: %w[pass_through drop bypass raise],
           default: "pass_through",
           desc: "Unknown tag handling"

    option :mathml2asciimath,
           type: :boolean, aliases: "-m",
           desc: "Convert MathML to AsciiMath"

    option :track_time,
           type: :boolean,
           desc: "Track time spent on each step"

    option :split_sections,
           type: :numeric,
           default: 0, banner: "LEVEL",
           desc: "Split sections into separate files up to a provided level"
    def convert(input = nil)
      options[:require]&.each { |r| require r }

      config = {
        input_options: input_options = {},
        input_processor: nil,
        output_options: output_options = {},
        output_processor: nil,
      }

      config[:input_processor] = options[:input_format]&.to_sym
      config[:output_processor] = options[:output_format]&.to_sym

      %i[
        external_images
        unknown_tags
        mathml2asciimath
        track_time
        split_sections
      ].each do |i|
        input_options[i] = options[i]
      end

      output = options[:output]

      begin
        Coradoc::Converter.(input, output, **config)
      rescue Converter::NoInputPathError => e
        warn "You must provide INPUT file as a file for this optionset."
        warn "Detail: #{e.message}"
      rescue Converter::NoOutputPathError => e
        warn "You must provide OUTPUT file as a file for this optionset."
        warn "Detail: #{e.message}"
      rescue Converter::NoProcessorError => e
        warn "No processor found for given input/output."
        warn "Hint: set -I/--input-format or -O/--output-format option."
        warn "Detail: #{e.message}"
      end
    end

    desc "version", "display version information"
    def version
      puts "Coradoc: v#{Coradoc::VERSION}"
      puts "[dependency] WordToMarkdown: v#{WordToMarkdown::VERSION}"
      if Gem.win_platform?
        puts "[dependency] LibreOffice: version not available on Windows"
      else
        puts "[dependency] LibreOffice: v#{WordToMarkdown.soffice.version}"
      end
    end
  end
end
