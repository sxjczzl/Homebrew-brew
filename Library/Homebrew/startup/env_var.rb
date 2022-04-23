# typed: true
# frozen_string_literal: true

# @api private
class MissingEnvironmentVariables < RuntimeError
  attr_reader :env

  def initialize(env)
    super("#{env} was not exported! Please call bin/brew directly!")
    @env = env
  end
end

# Helper module for getting environment variables which must be set.
#
# @api private
module EnvVar
  def self.[](env)
    raise MissingEnvironmentVariables, env unless ENV[env]

    ENV.fetch(env)
  end
end
