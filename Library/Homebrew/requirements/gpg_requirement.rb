require "requirement"

class GPGRequirement < Requirement
  fatal true
  default_formula "gpg"

  satisfy { which("gpg") || which("gpg2") }
end
