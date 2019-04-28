class CygwinRequirement < Requirement
  fatal true

  satisfy(build_env: false) { OS.cygwin? }

  def message
    "Cygwin is required."
  end
end
