module Coradoc
  module Element
    class Author
      attr_reader :email, :last_name, :first_name

      def initialize(first_name, last_name, email, middle_name = nil)
        @first_name = first_name
        @last_name = last_name
        @email = email
        @middle_name = middle_name
      end

      def to_adoc
        adoc = "#{@first_name} "
        adoc << "#{@middle_name} " if @middle_name
        adoc << @last_name.to_s
        adoc << " <#{@email}>" if @email
        adoc
      end
    end
  end
end
