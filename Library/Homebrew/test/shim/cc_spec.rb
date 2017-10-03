require "tempfile"

# set up temporary file, strip the preamble
# up to and including the #!/usr/bin/env ruby shebang
raise "failure" unless File.exist?("shims/super/cc")
script = Tempfile.new("CCShim").path
raise "failure2" unless
  system("<shims/super/cc awk '/^[#][!].usr.bin.env ruby/ {c=1; next} c==1 {print}' > '#{script}'")

load script

describe "Shims_Super_CC" do
  class Cmd1 < Cmd
    def initialize; end
  end
  describe "above_symbolically?" do
    it "nonexistent path is strict prefix of itself" do
      Cmd1.new.above_symbolically?("/aaaa", "/aaaa").should eql true
    end

    it "nonexistent path is under strict prefix of path" do
      Cmd1.new.above_symbolically?("/aaaa", "/aaaa/bbbb").should eql true
    end

    it "nonexistent path is only under strict prefix of path" do
      Cmd1.new.above_symbolically?("/aaaa", "/bbbb/bbbb").should eql false
    end

    it "file is under symbolic link to self" do
      target = Tempfile.new("CcTestTarget").path
      symlink = Tempfile.new("CcTestSymlink").path
      system("rm '#{symlink}' ; ln -s '#{target}' '#{symlink}'")

      Cmd1.new.above_symbolically?(target, symlink).should eql true
    end
  end
end
