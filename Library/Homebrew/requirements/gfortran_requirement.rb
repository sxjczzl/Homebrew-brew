class GfortranRequirement < Requirement
  fatal true
  default_formula "gcc"

  satisfy build_env: false do
    next false unless which "gfortran"
    next true unless @version
    gfortran_version = Utils.popen_read("gfortran", "--version").split("\n").first.split(" ").last.chomp
    Version.create(gfortran_version) >= Version.create(@version)
  end

  env do
    ENV.prepend_path "PATH", which("gfortran").dirname
    ENV["FC"] = "gfortran"
  end

  def initialize(tags)
    @version = tags.shift if /(\d\.)+\d/ =~ tags.first
    super
  end

  def message
    version_string = " #{@version}" if @version

    s = "GFortran #{version_string} or later is required to install this formula."
    s += super
    s
  end

  def inspect
    "#<#{self.class.name}: #{name.inspect} #{tags.inspect} version=#{@version.inspect}>"
  end
end
