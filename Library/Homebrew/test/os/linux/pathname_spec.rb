# frozen_string_literal: true

require "extend/pathname"

describe Pathname do
  let(:elf_dir) { described_class.new "#{TEST_FIXTURE_DIR}/elf" }
  let(:sho) { elf_dir/"libforty.so.0" }
  let(:sho_without_runpath_rpath) { elf_dir/"libhello.so.0" }
  let(:exec) { elf_dir/"hello_with_rpath" }

  describe "#interpreter" do
    it "returns interpreter" do
      expect(exec.interpreter).to eq "/lib64/ld-linux-x86-64.so.2"
    end

    it "returns nil when absent" do
      expect(sho.interpreter).to be_nil
    end
  end

  describe "#rpath" do
    it "prefers runpath over rpath when both are present" do
      expect(sho.rpath).to eq "runpath"
    end

    it "returns runpath or rpath" do
      expect(exec.rpath).to eq "@@HOMEBREW_PREFIX@@/lib"
    end

    it "returns nil when absent" do
      expect(sho_without_runpath_rpath.rpath).to be_nil
    end
  end
end
