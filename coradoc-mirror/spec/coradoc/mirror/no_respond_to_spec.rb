# frozen_string_literal: true

require 'spec_helper'

# Global CLAUDE.md rule #8: NEVER use `respond_to?` for type checking.
# This spec enforces it at the lib/ level for coradoc-mirror so future
# commits don't silently reintroduce it.
RSpec.describe 'no respond_to? type-dispatch in lib/' do
  let(:lib_dir) { File.expand_path('../../../lib/coradoc/mirror', __dir__) }

  it 'coradoc-mirror lib never uses respond_to?' do
    files = Dir.glob("#{lib_dir}/**/*.rb")
    expect(files).not_to be_empty

    offenders = files.each_with_object([]) do |file, list|
      File.readlines(file).each_with_index do |line, idx|
        next if line.strip.start_with?('#')

        list << "#{File.basename(file)}:#{idx + 1}: #{line.strip}" if line.include?('respond_to?')
      end
    end

    expect(offenders).to be_empty,
                         "respond_to? found in lib/ (use is_a? or rely on the type hierarchy):\n#{offenders.join("\n")}"
  end
end
