describe "brew bottle", :integration_test do
  it "builds a bottle for the given Formula" do
    begin
      expect { brew "install", "--build-bottle", testball }
        .to be_a_success

      expect { brew "bottle", "--no-rebuild", testball }
        .to output(/Formula not from core or any taps/).to_stderr
        .and not_to_output.to_stdout
        .and be_a_failure

      setup_test_formula "testball"

      # `brew bottle` should not fail with dead symlink
      # https://github.com/Homebrew/legacy-homebrew/issues/49007
      (HOMEBREW_CELLAR/"testball/0.1").cd do
        FileUtils.ln_s "not-exist", "symlink"
      end

      expect { brew "bottle", "--no-rebuild" , "--use-gzip", "testball" }
        .to output(/testball-0\.1.*\.bottle\.tar\.gz/).to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    ensure
      FileUtils.rm_f Dir.glob("testball-0.1*.bottle.tar.gz")
    end
  end

  it "builds an xz bottle for the given Formula" do
    begin
      expect { brew "install", "--build-bottle", testball }
        .to be_a_success

      setup_test_formula "testball", <<~EOS
        bottle do
          compression_type :xz
        end
      EOS

      expect { brew "bottle", "--no-rebuild", "testball" }
        .to output(/testball-0\.1.*\.bottle\.tar\.xz/).to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    ensure
      FileUtils.rm_f Dir.glob("testball-0.1*.bottle.tar.xz")
    end
  end
end
