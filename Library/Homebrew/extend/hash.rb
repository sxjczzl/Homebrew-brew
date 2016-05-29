class Hash
  def deep_merge(other)
    merge(other) do |key, v1, v2|
      if Hash === v1 && Hash == v2
        v1.deep_merge(v2)
      else
        v2
      end
    end
  end
end
