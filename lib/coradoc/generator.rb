module Coradoc
  class Generator

    # Escape asciidoc inline block delimiter
    # characters.
    #
    # Works by prepending a backslash to the all
    # delimiter characters in the string that are
    # adjacent to a whitespace.
    #
    # @param string [String] the string to escape
    # @param escape_chars [Array<String>] the characters to escape by prepending a backslash
    # @param pass_through [Array<String>] the characters to pass through by inserting in a pass:[] macro
    # @url https://github.com/metanorma/reverse_adoc/pull/72/files
    def self.escape_characters(string, escape_chars: [], pass_through: [])
      result = string.dup

      regex_chars = Regexp.escape(escape_chars.join)
      if !regex_chars.empty?
        result.gsub!(
          %r{((?<=\s)[#{regex_chars}]+)|([#{regex_chars}]+(?=\s))}
        ) do |match|
          match.chars.map do |c|
            "\\#{c}"
          end.join
        end
      end

      regex_pass = Regexp.escape(pass_through.join)
      if !regex_pass.empty?
        result.gsub!(
          %r{([#{regex_pass}]+)},
          "{pass:[\\1]}"
        )
      end

      result
    end

    def self.gen_adoc(content)
      puts "wtf pz"
      if content.is_a?(Array)
        puts 'is array'
        content.map do |elem|
          Coradoc::Generator.gen_adoc(elem)
        end.join
      elsif content.respond_to? :to_asciidoc
        puts 'respond to to_asciidoc'
        pp content
        content.to_asciidoc
      elsif content.respond_to? :to_adoc
        puts 'respond to adoc'
        pp content
        content.to_adoc
      elsif content.is_a?(String)
        puts 'is a string'
        pp content
        # "#{content.chomp}\n"
        content
      elsif content.nil?
        puts 'is nil'
        ""
      elsif content.is_a?(Parslet::Slice)
        content.to_s
      end
    end
  end
end
