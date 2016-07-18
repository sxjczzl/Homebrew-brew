require "requirements/gpg_requirement"

class Gpg
  GPG_EXECUTABLE = GPGRequirement.new.gpg2 || GPGRequirement.new.gpg

  def self.available?
    File.exist?(GPG_EXECUTABLE).to_s && File.executable?(GPG_EXECUTABLE)
  end
end
