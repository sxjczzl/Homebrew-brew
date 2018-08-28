require "requirement"

class MonoRequirement < Requirement
  cask "mono-mdk"
  fatal true

  satisfy build_env: false do
    setup_mono
    next false unless @mono
    next true
  end

  def initialize(tags = [])
    @version = tags.shift if /(\d+\.)+\d/ =~ tags.first
    super(tags)
  end

  def message
    version_string = " #{@version}" if @version
    s = "Mono #{version_string} is required to install this formula.\n"
    s += super
    s
  end

  def inspect
    "#<#{self.class.name}: #{name.inspect} #{tags.inspect} version=#{@version.inspect}>"
  end

  def display_s
    if @version
      if exact_version?
        op = "="
      else
        op = ">="
      end
      "#{name} #{op} #{version_without_plus}"
    else
      name
    end
  end

  private

  def setup_mono
    mono = preferred_mono
    return unless mono
    @mono = mono
    @path = mono.parent.parent
  end

  def possible_mono
    monos = []
    monos << which("mono")
    # Dir['/Library/Frameworks/Mono.framework/Versions/*/Commands/mono'].each {|x| monos << Pathname.new(x)}
    File.write("/tmp/plausiblemono#{@version}.log", "i am considering amongst #{monos}")
    monos
  end

  def preferred_mono
    possible_mono.detect do |mono|
      File.write("/tmp/testingmono#{@version}.log", "i think #{mono} looks pretty sexy tbh is it executable? #{mono&.executable?} is it satisfying? #{satisfies_version(mono)}")
      next false unless mono&.executable?
      next true if satisfies_version(mono)
    end
  end

  def satisfies_version(mono)
    mono ||= ""
    mono_version_s = Utils.popen_read(mono, "--version", err: :out)[/Mono JIT compiler version (\d+\.\d+)/, 1]
    return false unless mono_version_s
    mono_version = Version.create(mono_version_s)
    needed_version = Version.create(version_without_plus)
    File.write("/tmp/pony#{mono_version}_#{needed_version}.log", "i desire #{needed_version} and have #{mono_version}")
    if exact_version?
      mono_version == needed_version
    else
      mono_version >= needed_version
    end
  end

  def version_without_plus
    if exact_version?
      @version
    else
      @version && @version[0, @version.length - 1] || "0"
    end
  end

  def exact_version?
    @version && @version.to_s.chars.last != "+"
  end
end

require "extend/os/requirements/mono_requirement"
