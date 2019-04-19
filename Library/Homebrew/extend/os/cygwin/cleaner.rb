class Cleaner
  private

  def executable_path?(path)
    path.extname == ".exe" || path.text_executable?
  end
end
