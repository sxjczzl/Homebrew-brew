
# A BrewCmd is a `brew` subcommand, such as "update", "info", "tap",
# or "install". It defines how to run the command, and may provide
# metadata such as a summary, helptext, and description of its options.
#
# Commands may be implemented in different ways; BrewCmd is the common
# superclass for all of them. Commands may be implemented as:
#   * Ruby class definitions of BrewCmd subclasses
#   * As a special case, foo.rb files containing FooBrewCmd definitions
#     which can be located and loaded automatically.
#   * Ruby scripts
#   * Arbitrary executables, such as shell scripts
# BrewCmd itself is effectively abstract. All the different command implementations
# are supported by subclasses.
#
# In the documentation for this class, "<cmd>" means the name of the command.
class BrewCmd
  # The command's name.
  def name
  end

  # A short (<60 chars) one-line summary of this command, suitable for
  # use in lists of multiple commands. Nil if no summary is available.
  def summary
  end

  # Multi-line helptext to be displayed for `brew help <cmd>` or
  # `brew <cmd> --help`. Nil if no helptext is available.
  def helptext
  end

  # Description of the command line options this supports, as a CmdOptions
  # object. Nil if a description is unavailable, in which case it may
  # support options, but it just doesn't tell you what they are.
  def options
  end

  # A symbol indicating the implementation type of this command. May be:
  #   :ruby_class_file    - a <cmd>.rb file in the new BrewCmd class style
  #   :ruby_function_file - a <cmd>.rb file in the old single-function
  #                           internal command style
  #   :ruby_script        - a <cmd>.rb file that runs as a script
  #   :external_exe       - an external executable command
  # The list of implementation types is open-ended, so other symbols may
  # be returned as well.
  def implementation_type
  end

  # Pathname of the file that implements this command (e.g. the <cmd>.rb source file
  # or the external executable command). Nil if unknown or there is none.
  def implementation_file
  end

  # True if this is an internal command shipped with brew itself
  def internal_cmd?
  end

  # Whether this command implements its own handling of the "--help" option.
  # When true, `brew <cmd> --help` should just call run(), passing along "--help"
  # as one of the arguments, instead of doing the normal display of what
  # helptext() returns. This is to support the older style of script and
  # external executable commands, which were expected to do their own --help
  # handling.
  def handles_help_itself?
  end

  # Performs the actions of this command.
  # It should set Homebrew.failed = true to indicate failure. Raising an
  # exception is also considered failure, and may cause diagnostics to be printed.
  # In the case of some external commands, run() never returns because the
  # external command is exec'ed and takes over the process.
  def run
    raise "run() is not implemented for class #{self.class.name}"
  end

  # Displays the helptext for this command
  def display_help
    if helptext.nil?
      puts "No help is available for command 'brew #{name}'"
    else
      puts helptext
    end
  end

  # Gets the BrewCmd object for a command, looking it up by name.
  def self.[](name)
    BrewCmdLoader.new.lookup(name)
  end
end


class BrewCmdLoader

  COMMANDS = {}

  # Converts a formula name to the corresponding class name.
  # This is a copy of Formulary.class_s, duplicated here to avoid having
  # to require "formulary".
  def self.class_s(name)
    class_name = name.capitalize
    class_name.gsub!(/[-_.\s]([a-zA-Z0-9])/) { $1.upcase }
    class_name.tr!("+", "x")
    class_name
  end

  # Converts a command name to the corresponding <Cmd>BrewCmd class name
  def self.cmd_class_s(name)
    class_s(name) + "BrewCmd"
  end

  # Converts a command name to the corresponding function name used by old-style
  # internal commands
  def self.cmd_function_s(name)
    name.tr("-", "_").downcase
  end

  # Gets the BrewCmd object for a command, looking it up by name.
  def lookup(name)
    if COMMANDS.has_key?(name)
      COMMANDS[name]
    else
      COMMANDS[name] = search_and_load_cmd(name)
    end
  end

  # Auto-taps absent taps for well-known commands
  # Returns the tap it added if it did so, or nil if it did not add
  # one
  def self.lookup_well_known_tap_commands(cmd)
    # Second-chance lookup for well-known commands in non-default taps
    require "tap"
    possible_tap = case cmd
                     when "brewdle", "brewdler", "bundle", "bundler"
                       Tap.fetch("Homebrew", "bundle")
                     when "cask"
                       Tap.fetch("caskroom", "cask")
                     when "services"
                       Tap.fetch("Homebrew", "services")
                   end

    if possible_tap && !possible_tap.installed?
      brew_uid = HOMEBREW_BREW_FILE.stat.uid
      tap_commands = []
      if Process.uid.zero? && !brew_uid.zero?
        tap_commands += %W[/usr/bin/sudo -u ##{brew_uid}]
      end
      tap_commands += %W[#{HOMEBREW_BREW_FILE} tap #{possible_tap}]
      safe_system *tap_commands
      possible_tap
    else
      nil
    end
  end

  private

  def search_and_load_cmd(name)
    # Locate internal commands
    internal_cmd_dirs = [HOMEBREW_LIBRARY_PATH.join("cmd")]
    if ARGV.homebrew_developer?
      internal_cmd_dirs << HOMEBREW_LIBRARY_PATH.join("dev-cmd")
    end
    internal_cmd_dirs.each do |dir|
      file = dir.join(name+".rb")
      if File.file?(file)
        return load_internal_cmd(name, file)
      end
    end

    # External commands: arbitrary exes to be exec'ed
    exe_file = which "brew-#{name}"
    if exe_file
      return ExternalExeCmd(exe_file)
    end

    # External commands: .rb files to be required
    rb_exe_file = which "brew-#{name}.rb"
    if rb_exe_file
      return load_rb_exe_cmd(name, rb_exe_file)
    end
    # Well-known commands in non-default taps
  end

  # Load an "internal" command shipped with Homebrew. Supports the legacy
  # "function in Homebrew module" and new "BrewCmd class definition" forms
  def load_internal_cmd(name, file)
    if looks_like_cmd_class_file?(name, file)
      load_class_file_cmd(name, file)
    else
      load_internal_function_cmd(name, file)
    end
  end

  def load_rb_exe_cmd(name, file)
    if looks_like_cmd_class_file?(name, file)
      load_class_file_cmd(name, file)
    else
      RubyScriptCmd.new(name, file)
    end
  end

  # Loads new-style <Cmd>BrewCmd class command definition file
  def load_class_file_cmd(name, file)
    require file
    Object.const_get(BrewCmdLoader.cmd_class_s(name)).new(name)
  end

  # Loads an old-style Homebrew.<cmd> function file
  def load_internal_function_cmd(name, file)
    require file
    FunctionInternalCmd.new(name, file)
  end

  # True if the file looks like a <Cmd>BrewCmd class definition. This determines whether
  # it will be treated as a new BrewCmd class style definition, or an old style function
  # or script definition. Strictly, it looks for a line with "class <Cmd>BrewCmd" in it.
  def looks_like_cmd_class_file?(name, file)
    cmd_class_name = BrewCmdLoader.cmd_class_s(name)
    File.foreach(file).any? { |line| line =~ /^\s*class\s+#{cmd_class_name}/ }
  end
end

# A command that has its own class to define it. This is the kind typically found in
# new-style command class definition files. It has support for DSL via class-level
# properties, like Formula.
class BrewCmdClass < BrewCmd

  # Named cmd_name to avoid conflict with existing Class.name
  #attr_rw :cmd_name
  #attr_rw :summary
  #attr_rw :helptext

  def initialize(name)
    @name = name
  end

  attr_reader :name

  class << self
    attr_rw :cmd_name
    attr_rw :summary
    attr_rw :helptext
  end

  def summary
    self.class.summary
  end

  def helptext
    self.class.helptext
  end
end

# Wraps an old-style single-function internal command definition.
# Does not support summary, helptext, or options.
# The functions are always defined in the Homebrew module.
class FunctionInternalCmd < BrewCmd
  def initialize(name, file)
    @name = name
    @implementation_file = file
    @function_name = BrewCmdLoader.cmd_function_s(name)
  end

  def name
    @name
  end

  def implementation_type
    :ruby_function_file
  end

  def implementation_file
    @implementation_file
  end

  def internal_cmd?
    true
  end

  def handles_help_itself?
    false
  end

  def run
    Homebrew.send @function_name
  end
end

class RubyScriptCmd < BrewCmd
  def initialize(name, file)
    @name = name
    @implementation_file = file
    @implementation_type = :ruby_script
  end

  attr_reader :name
  attr_reader :implementation_file
  attr_reader :implementation_type

  def internal_cmd?
    false
  end

  def handles_help_itself?
    true
  end

  def run
    load @implementation_file
  end

end

class ExternalExeCmd < BrewCmd
  def initialize(name, file)
    @name = name
    @implementation_file = file
    @implementation_type = :external_exe
  end

  attr_reader :name
  attr_reader :implementation_file
  attr_reader :implementation_type

  def internal_cmd?
    false
  end

  def handles_help_itself?
    true
  end

  def run
    %w[CACHE LIBRARY_PATH].each do |e|
      ENV["HOMEBREW_#{e}"] = Object.const_get("HOMEBREW_#{e}").to_s
    end
    exec @implementation_file
  end

end

