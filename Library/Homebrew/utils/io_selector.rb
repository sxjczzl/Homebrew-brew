require "delegate"
require "English"

require "extend/io"

module Utils
  #
  # The class `IOSelector` is a wrapper for `IO::select` with the
  # added benefit that it spans the streams' lifetimes.
  #
  # The class accepts multiple IOs which must be open for reading.
  # It then notifies the client as data becomes available
  # per-stream.
  #
  # Its main use is to allow a client to read both `stdout` and
  # `stderr` of a subprocess in a way that avoids buffer-related
  # deadlocks.
  #
  # For a more in-depth explanation, see:
  #   https://github.com/Homebrew/brew/pull/2466
  #
  class IOSelector < DelegateClass(Hash)
    attr_reader :separator

    alias all_streams keys
    alias all_tags values
    alias tag_of fetch

    def self.each_line_from(streams = {},
      separator = $INPUT_RECORD_SEPARATOR, &block)
      new(streams, separator).each_line_nonblock(&block)
    end

    def initialize(streams = {},
      separator = $INPUT_RECORD_SEPARATOR)
      super(streams.invert.compare_by_identity)
      @separator = separator
    end

    def each_line_nonblock
      each_readable_stream_until_eof do |stream|
        line = stream.readline_nonblock(separator) || ""
        yield(tag_of(stream), line)
      end
      close_streams
    end

    def pending_streams
      @pending_streams ||= all_streams.dup
    end

    private

    def each_readable_stream_until_eof(&block)
      loop do
        readable_streams.each do |stream|
          pending_streams.delete(stream) if stream.eof?
          yield_gracefully(stream, &block)
        end
        break if pending_streams.empty?
      end
    end

    def readable_streams
      IO.select(pending_streams)[0]
    end

    def yield_gracefully(stream)
      yield(stream)
    rescue IO::WaitReadable, IO::WaitWritable, EOFError
      # We'll be back until/unless EOF
      return
    end

    def close_streams
      all_streams.each(&:close_read)
    end
  end
end
