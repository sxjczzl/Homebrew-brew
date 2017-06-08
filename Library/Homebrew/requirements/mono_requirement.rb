class MonoRequirement < Requirement
  fatal true
  default_formula "mono"

  def initialize(tags)
    @version = tags.shift if /(\d\.)+\d/ =~ tags.first
    raise "MonoRequirement requires a version!" unless @version
    super
  end

  satisfy(build_env: false) { new_enough_mono }

  env do
    ENV.prepend_path "PATH", new_enough_mono.dirname
  end

  def message
    s = "Mono >= #{@version} is required to install this formula."
    s += super
    s
  end

  def inspect
    "#<#{self.class.name}: #{name.inspect} #{tags.inspect} version=#{@version.inspect}>"
  end

  def display_s
    if @version
      "#{name} >= #{@version}"
    else
      name
    end
  end

  private

  def new_enough_mono
    monos.detect { |mono| new_enough?(mono) }
  end

  def monos
    monos = which_all("mono")
    mono_formula = Formula["mono"]
    if mono_formula && mono_formula.installed?
      monos.unshift mono_formula.bin/"mono"
    end
    monos.uniq
  end

  def new_enough?(mono)
    version_info = Utils.popen_read(mono, "-V").strip
    /^[\w ]*(?<version>\d+\.\d+.\d+).\d+( |$)/i =~ version_info && Version.create(version) >= min_version
  end

  def min_version
    @min_version ||= Version.create(@version)
  end
end
