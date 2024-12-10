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
end
