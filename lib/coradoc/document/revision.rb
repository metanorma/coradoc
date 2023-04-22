module Coradoc
  class Document::Revision
    attr_reader :number, :date, :remark

    def initialize(number, options = {})
      @number = number
      @date = options.fetch(:date, nil)
      @remark = options.fetch(:remark, nil)
    end
  end
end
