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
    DEFAULT_BUFFER_SIZE = 0x1000

    attr_reader :separator

    alias all_streams keys
    alias all_tags values
    alias tag_of fetch

    def self.binread_nonblock_from(streams,
      buffer_size = DEFAULT_BUFFER_SIZE)
      new(streams, nil).binread_nonblock(buffer_size)
    end

    def self.each_line_from(streams = {},
      separator = $INPUT_RECORD_SEPARATOR, &block)
      new(streams, separator).each_line_nonblock(&block)
    end

    def self.each_chunk_from(streams, maxlen, outbuf = nil, &block)
      selector = new(streams, nil)
      selector.each_chunk_nonblock(maxlen, outbuf, &block)
    end

    def initialize(streams = {},
      separator = $INPUT_RECORD_SEPARATOR)
      unless streams.is_a?(Hash)
        streams = Hash[streams.each_with_index.to_a.map(&:reverse)]
      end
      super(streams.invert.compare_by_identity)
      @separator = separator
    end

    def binread_nonblock(buffer_size = DEFAULT_BUFFER_SIZE)
      chunk_buffer = "".b
      with_tagged_buffers("".b) do |result_buffers|
        each_chunk_nonblock(buffer_size, chunk_buffer) do |tag|
          result_buffers[tag] << chunk_buffer
        end
      end
    end

    def each_line_nonblock
      each_readable_stream_until_eof do |stream|
        line = stream.readline_nonblock(separator) || ""
        yield(tag_of(stream), line)
      end
      close_streams
    end

    def each_chunk_nonblock(maxlen, outbuf = nil)
      each_readable_stream_until_eof do |stream|
        chunk = stream.read_nonblock(maxlen, outbuf) || "".b
        yield(tag_of(stream), chunk)
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

    def with_tagged_buffers(value)
      tagged_buffers = Hash[all_tags.map { |tag| [tag, value.dup] }]
      yield(tagged_buffers)
      tagged_buffers
    end

    def close_streams
      all_streams.each(&:close_read)
    end
  end
end
