module Coradoc
  module Element
    class Bibliography < Base
      attr_accessor :id, :title, :entries

      def initialize(options = {})
        @id = options.fetch(:id, nil)
        @anchor = @id.nil? ? nil : Inline::Anchor.new(id: @id)
        @title = options.fetch(:title, nil)
        @entries = options.fetch(:entries, nil)
      end

      def to_adoc
        adoc = "#{gen_anchor}\n"
        adoc << "[bibliography]"
        adoc << "== #{@title}\n\n"
        @entries.each do |entry|
          adoc << "#{entry.to_adoc}\n"
        end
        adoc
      end
    end
  end
end
