require "requirements/gpg_requirement"

class Gpg
  GPG_EXECUTABLE = GPGRequirement.new.gpg2 || GPGRequirement.new.gpg

  def self.available?
    File.exist?(GPG_EXECUTABLE).to_s && File.executable?(GPG_EXECUTABLE)
  end

  def self.create_test_key(path)
    raise "No GPG present to test against!" unless available?

    (path/"batchgpg").write <<-EOS.undent
      Key-Type: RSA
      Key-Length: 2048
      Subkey-Type: RSA
      Subkey-Length: 2048
      Name-Real: Testing
      Name-Email: testing@foo.bar
      Expire-Date: 1d
      %commit
    EOS
    system GPG_EXECUTABLE, "--batch", "--gen-key", "batchgpg"
  end
end
