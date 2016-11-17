require "fileutils"

class CaskPin
  def initialize(c)
    @c = c
  end

  def path
    @path ||= @c.metadata_master_container_path.to_s + "/pinned"
  end

  def pin
    FileUtils.touch path
  end

  def unpin
    FileUtils.rm path
  end

  def pinned?
    File.exists? path
  end

end
