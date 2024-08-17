module Coradoc
  def self.strip_unicode(str)
    str.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "")
  end

  def self.a_single?(obj, klass)
    obj.is_a?(klass) ||
      (obj.is_a?(Array) && obj.length == 1 && obj.first.is_a?(klass))
  end
end
