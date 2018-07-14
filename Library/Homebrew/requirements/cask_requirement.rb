require "requirement"
require "hbc/cask_loader"

class CaskRequirement < Requirement
  fatal true

  def initialize(tags = [])
    @cask = @name = tags.shift
    raise UnsatisfiedRequirements, message unless @cask
    @cask_loaded = Hbc::CaskLoader.load(@cask)
    super(tags)
  end

  satisfy(build_env: false) { installed? && !outdated? }

  def installed?
    @cask_loaded.installed?
  end

  def outdated?
    @cask_loaded.outdated?
  end

  def install
    brew "cask", "install", @cask
  end

  def upgrade
    brew "cask", "upgrade", @cask
  end

  def message
    if @cask
      "Cask requirement #{@cask} is not met"
    else
      "MetaFormula DSL `depends_on :cask => \"cask_name\"` requires a cask_name"
    end
  end

  def to_s
    @name
  end

  module Util
    private

    def testing?
      ENV.include? "HOMEBREW_TEST_TMPDIR"
    end

    # Using `system` makes testing tricky
    # Here we dynamically load test configuration depends on ENV
    def brew(*args)
      ruby_args = ["-W0"]

      # If testing, we need to run brew.rb with the test configuration
      # This works because test/support/lib get into the first of $LOAD_PATH,
      # so all `require "config"` will require test/support/lib/config.rb
      if testing?
        ruby_args += %W[-I#{HOMEBREW_LIBRARY_PATH}/test/support/lib -rconfig]
      end

      # cannot use HOMEBREW_BREW_FILE because this environment variable got changed in :integration_test tests
      brew_file =  (HOMEBREW_LIBRARY_PATH/"brew.rb").resolved_path.to_s
      ruby_args << brew_file

      safe_system(RUBY_PATH, *ruby_args, *args)
    end
  end

  include Util
end
