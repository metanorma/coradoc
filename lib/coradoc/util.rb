module Coradoc
  def self.strip_unicode(str, only: nil)
    str = str.gsub(/\A[[:space:]]+/, "") unless only == :end
    str = str.gsub(/[[:space:]]+\z/, "") unless only == :begin
    str
  end

  def self.a_single?(obj, klass)
    obj.is_a?(klass) ||
      (obj.is_a?(Array) && obj.length == 1 && obj.first.is_a?(klass))
  end

  # @param [Object] left
  # @param [Object] right
  # @return [Boolean] true if the two objects are deep duplicates
  def self.is_deep_dup?(left, right)
    case right
    when Hash
      # First, check that the keys are all identical.
      # Then, check that the values are identical.
      left.is_a?(Hash) && left.keys == right.keys &&
      [left, right].map(&:values).zip.all? do |(a, b)|
        is_deep_dup?(a, b)
      end
    when Array
      # Check that the values are all identical.
      left.is_a?(Array) && left.length == right.length &&
        [left, right].zip.all? do |(a, b)|
          is_deep_dup?(a, b)
        end
    else
      # Check that both values are identical.
      # warn "same same, but different!"
      left == right && left.is_a?(Symbol) || !left.equal?(right)
    end
  end
end
