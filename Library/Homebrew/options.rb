require "set"

class Option
  attr_reader :name, :value, :description, :flag

  def initialize(arg, description = "")
    arg = arg.match(/^([^=]+=?)(.+)?$/)
    @name = arg[1]
    @value = arg[2]
    @flag = "--#{name}#{value}"
    @description = description
  end

  def to_s
    flag
  end

  def <=>(other)
    return unless Option === other
    flag <=> other.flag
  end

  def ==(other)
    instance_of?(other.class) && flag == other.flag
  end
  alias_method :eql?, :==

  def hash
    flag.hash
  end

  def inspect
    "#<#{self.class.name}: #{flag.inspect}>"
  end
end

class DeprecatedOption
  attr_reader :old, :current

  def initialize(old, current)
    @old = old
    @current = current
  end

  def old_flag
    "--#{old}"
  end

  def current_flag
    "--#{current}"
  end

  def ==(other)
    instance_of?(other.class) && old == other.old && current == other.current
  end
  alias_method :eql?, :==
end

class Options
  include Enumerable

  attr_reader :options
  protected :options

  def self.create(array = [])
    options = Hash.new
    array.each do |option|
      option = Option.new(option.strip_prefix("--")) unless option.is_a?(Option)
      options[option.name] = option
    end
    new options
  end

  # We store options in a Hash (option name => option object),
  # because they may have different value under the same name.
  def initialize(options)
    @options = options
  end

  def each(*args, &block)
    @options.each_value(*args, &block)
  end

  def <<(o)
    opt = @options[o.name]
    if opt
      @options[o.name] = o if opt.value.nil? && !o.value.nil?
    else
      @options[o.name] = o
    end
    self
  end

  def +(other)
    new_options = @options.merge(other.options) do |_name, old_opt, new_opt|
      if old_opt.value.nil? && !new_opt.value.nil?
        new_opt
      else
        old_opt
      end
    end
    self.class.new new_options
  end
  alias_method :|, :+

  def -(other)
    self.class.new Hash[@options.reject { |name, _option| other.options.key?(name) }]
  end

  def &(other)
    self.class.new Hash[@options.select { |name, _option| other.options.key?(name) }]
  end

  def *(arg)
    @options.values * arg
  end

  def empty?
    @options.empty?
  end

  def as_flags
    map(&:flag)
  end

  def include?(o)
    any? { |opt| opt == o || opt.name == o || opt.flag == o }
  end

  def to_a
    @options.values
  end
  alias_method :to_ary, :to_a

  def inspect
    "#<#{self.class.name}: #{to_a.inspect}>"
  end
end

module Homebrew
  def dump_options_for_formula(f)
    f.options.sort_by(&:flag).each do |opt|
      puts "#{opt.flag}\n\t#{opt.description}"
    end
    puts "--devel\n\tInstall development version #{f.devel.version}" if f.devel
    puts "--HEAD\n\tInstall HEAD version" if f.head
  end
end
