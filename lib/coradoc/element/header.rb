module Coradoc
  module Element
    class Header < Base
      attr_accessor :title, :author, :revision

      declare_children :title

      def initialize(title:, author: nil, revision: nil)
        @title = title
        @author = author
        @revision = revision
      end

      def to_adoc
        adoc = "= #{@title}\n"
        adoc << @author.to_adoc if @author
        adoc << @revision.to_adoc if @revision
        adoc
      end
    end
  end
end
