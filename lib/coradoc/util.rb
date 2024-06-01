module Coradoc
  def self.strip_unicode(str)
    str.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "")
  end
end
