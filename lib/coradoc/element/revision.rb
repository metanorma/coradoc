module Coradoc
  module Element
    class Revision
      attr_reader :number, :date, :remark

      def initialize(number, options = {})
        @number = number
        @date = options.fetch(:date, nil)
        @remark = options.fetch(:remark, nil)
      end

      def to_adoc
        if @date.nil? && @remark.nil?
          "v#{@number}\n"
        elsif @remark.nil?
          "#{@number}, #{@date}\n"
        elsif @date.nil?
          "#{@number}: #{@remark}\n"
        else
          "#{@number}, #{@date}: #{@revision}\n"
        end
      end
    end
  end
end
