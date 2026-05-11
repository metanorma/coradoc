# frozen_string_literal: true

module Coradoc
  module CoreModel
    module IdGenerator
      def self.generate_from_title(title)
        return nil if title.nil? || title.to_s.strip.empty?

        '_' + title.to_s.downcase
                   .gsub(/[^a-z0-9\s]/, '')
                   .gsub(/\s+/, '_')
                   .gsub(/^_+|_+$/, '')
      end
    end
  end
end
