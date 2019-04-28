class CoreTap < Tap
  # @private
  def initialize
    super "Homebrew", "core"
    @full_name = "Homebrew/cygwinbrew-core"
  end
end
