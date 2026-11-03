# frozen_string_literal: true

require 'yaml'

module Coradoc
  module Roundtrip
    # The set of Cases to check: fixture files named in corpus.yml, an
    # optional external directory, and the generated edge cases.
    class Corpus
      CONFIG = File.join(ROOT, 'corpus.yml')
      EXTRA_EXTENSIONS = { '.adoc' => :asciidoc, '.md' => :markdown, '.markdown' => :markdown }.freeze

      # @param format [Symbol, nil] restrict to :asciidoc or :markdown
      # @return [Array<Case>]
      def self.cases(format: nil, extra: ENV.fetch('CORADOC_ROUNDTRIP_EXTRA', nil))
        new(extra: extra).cases.select { |c| format.nil? || c.format == format }
      end

      def initialize(extra: nil, root: REPO_ROOT)
        @extra = extra
        @root = root
      end

      def cases
        (fixture_cases + extra_cases + EdgeCases.all).sort_by(&:id)
      end

      private

      def fixture_cases
        YAML.safe_load_file(CONFIG).flat_map do |format, globs|
          globs.flat_map { |glob| Dir[File.join(@root, glob)] }.uniq.map do |path|
            file_case(path, format.to_sym, @root)
          end
        end
      end

      def extra_cases
        return [] unless @extra && Dir.exist?(@extra)

        Dir[File.join(@extra, '**', '*')].filter_map do |path|
          format = EXTRA_EXTENSIONS[File.extname(path)]
          file_case(path, format, @extra) if format && File.file?(path)
        end
      end

      def file_case(path, format, base)
        relative = path.delete_prefix("#{base}/")
        Case.new("#{format}:#{relative}", format, File.read(path, encoding: 'UTF-8'), relative)
      end
    end
  end
end
