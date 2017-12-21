class Gpg
  def self.available?
    File.executable?(GPG2Requirement.new.executable.to_s)
  end

  def self.executable
    GPG2Requirement.new.executable
  end

  def self.create_test_key(path)
    odie "No GPG present to test against!" unless available?

    (path/"batch.gpg").write <<~EOS
      Key-Type: RSA
      Key-Length: 2048
      Subkey-Type: RSA
      Subkey-Length: 2048
      Name-Real: Testing
      Name-Email: testing@foo.bar
      Expire-Date: 1d
      %no-protection
      %commit
    EOS
    system executable, "--batch", "--gen-key", "batch.gpg"
  end

  def self.cleanup_test_processes!
    odie "No GPG present to test against!" unless available?
    gpgconf = Pathname.new(executable).parent/"gpgconf"

    system gpgconf, "--kill", "gpg-agent"
    system gpgconf, "--homedir", "keyrings/live", "--kill",
                                 "gpg-agent"
  end

  def self.test(path)
    create_test_key(path)
    begin
      yield
    ensure
      cleanup_test_processes!
    end
  end
end
