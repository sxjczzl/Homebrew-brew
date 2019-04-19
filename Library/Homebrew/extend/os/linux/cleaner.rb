class Cleaner
  private

  def executable_path?(path)
    if OS.cygwin?
       path.extname == ".exe" || path.text_executable?
    else
       path.elf? || path.text_executable?
    end
  end
end
