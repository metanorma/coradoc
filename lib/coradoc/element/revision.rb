module Coradoc
  module Element
    class Revision < Base
      attr_accessor :number, :date, :remark

      declare_children :number, :date, :remark

      def initialize(number:, date: nil, remark: nil)
        @number = number
        @date = date
        @remark = remark
      end

      def to_adoc
        if @date.nil? && @remark.nil?
          "v#{@number}\n"
        elsif @remark.nil?
          "#{@number}, #{@date}\n"
        elsif @date.nil?
          "#{@number}: #{@remark}\n"
        else
          "#{@number}, #{@date}: #{@remark}\n"
        end
      end
    end
  end
end
