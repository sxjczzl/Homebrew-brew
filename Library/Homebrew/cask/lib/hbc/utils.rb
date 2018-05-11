require "yaml"
require "open3"
require "stringio"

BUG_REPORTS_URL = "https://github.com/Homebrew/homebrew-cask#reporting-bugs".freeze

# global methods

def odebug(title, *sput)
  return unless ARGV.debug?
  puts Formatter.headline(title, color: :magenta)
  puts sput unless sput.empty?
end

module Hbc
  module Utils
    def self.gain_permissions_remove(path, command: SystemCommand)
      if path.respond_to?(:rmtree) && path.exist?
        gain_permissions(path, ["-R"], command) do |p|
          if p.parent.writable?
            p.rmtree
          else
            command.run("/bin/rm",
                        args: ["-r", "-f", "--", p],
                        sudo: true)
          end
        end
      elsif File.symlink?(path)
        gain_permissions(path, ["-h"], command, &FileUtils.method(:rm_f))
      end
    end

    def self.gain_permissions(path, command_args, command)
      tried_permissions = false
      tried_ownership = false
      begin
        yield path
      rescue StandardError
        # in case of permissions problems
        unless tried_permissions
          # TODO: Better handling for the case where path is a symlink.
          #       The -h and -R flags cannot be combined, and behavior is
          #       dependent on whether the file argument has a trailing
          #       slash.  This should do the right thing, but is fragile.
          command.run("/usr/bin/chflags",
                      must_succeed: false,
                      args:         command_args + ["--", "000", path])
          command.run("/bin/chmod",
                      must_succeed: false,
                      args:         command_args + ["--", "u+rwx", path])
          command.run("/bin/chmod",
                      must_succeed: false,
                      args:         command_args + ["-N", path])
          tried_permissions = true
          retry # rmtree
        end
        unless tried_ownership
          # in case of ownership problems
          # TODO: Further examine files to see if ownership is the problem
          #       before using sudo+chown
          ohai "Using sudo to gain ownership of path '#{path}'"
          command.run("/usr/sbin/chown",
                      args: command_args + ["--", current_user, path],
                      sudo: true)
          tried_ownership = true
          # retry chflags/chmod after chown
          tried_permissions = false
          retry # rmtree
        end
      end
    end

    def self.current_user
      Etc.getpwuid(Process.euid).name
    end

    def self.path_occupied?(path)
      File.exist?(path) || File.symlink?(path)
    end

    def self.error_message_with_suggestions
      <<~EOS
        Follow the instructions here:
          #{Formatter.url(BUG_REPORTS_URL)}
      EOS
    end

    def self.method_missing_message(method, token, section = nil)
      poo = []
      poo << "Unexpected method '#{method}' called"
      poo << "during #{section}" if section
      poo << "on Cask #{token}."

      opoo(poo.join(" ") + "\n" + error_message_with_suggestions)
    end

    def self.gpg(args: [], command: SystemCommand, **options)
      executable = Formula["gnupg"].opt_bin/"gpg"

      homebrew_keyring = (HOMEBREW_CACHE/"gpg/homebrew-keyring.gpg").tap do |path|
        path.dirname.mkpath
      end

      # Ensure GPG installation is initialized.
      command.run!(executable, args: ["--list-keys"], print_stdout: false, print_stderr: false)

      command.run!(executable, args: ["--no-default-keyring", "--keyring", homebrew_keyring, *args], **options)
    end
  end
end
