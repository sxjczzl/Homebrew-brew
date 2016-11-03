class Testbottest < Formula
  desc "Minimal C program and Makefile used for testing Homebrew."
  homepage "https://github.com/Homebrew/brew"
  url "file://#{File.expand_path("..", __FILE__)}/tarballs/testbottest-0.1.tbz"
  sha256 "2c1423c97e4cbfd00a2e96fcecd7e42583bf76416f5eaaf83b400ea3c8690d80"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    assert_equal "testbottest\n", shell_output("#{bin}/testbottest")
  end
end
