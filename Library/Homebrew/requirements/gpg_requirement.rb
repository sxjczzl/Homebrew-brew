require "requirement"

class GPGRequirement < Requirement
  fatal true
  default_formula "gnupg2"

  satisfy { which("gpg2") || which("gpg") }
end
