require "utils/io_selector"

describe Utils::IOSelector do
  describe "given text streams" do
    let(:first_pipe) { IO.pipe }
    let(:second_pipe) { IO.pipe }

    let(:first_reader) { first_pipe[0] }
    let(:second_reader) { second_pipe[0] }

    let(:first_writer) { first_pipe[1] }
    let(:second_writer) { second_pipe[1] }

    let(:queues) { { first: Queue.new, second: Queue.new } }

    let(:write_first!) do
      thread = Thread.new(first_writer, queues[:second]) do |io, queue|
        io.puts "Lorem"
        wait(1).for { queue.pop }.to end_with("\n")
        io.puts "dolor"
        io.close
      end
      thread.abort_on_exception = true
      thread
    end

    let(:write_second!) do
      thread = Thread.new(second_writer, queues[:first]) do |io, queue|
        wait(1).for { queue.pop }.to end_with("\n")
        io.puts "ipsum"
        wait(1).for { queue.pop }.to end_with("\n")
        io.puts "sit"
        io.puts "amet"
        io.close
      end
      thread.abort_on_exception = true
      thread
    end

    let(:queue_feeder) do
      lambda do |proc_under_test, *args, &block|
        proc_under_test.call(*args) do |tag, string_received|
          queues[tag] << string_received
          block.call(tag, string_received)
        end
      end
    end

    before do
      allow_any_instance_of(Utils::IOSelector)
        .to receive(:each_line_nonblock)
        .and_wrap_original do |*args, &block|
        queue_feeder.call(*args, &block)
      end

      write_first!
      write_second!
    end

    after do
      write_first!.exit
      write_second!.exit
    end

    describe "::each_line_from" do
      subject do
        line_hash = { first: "", second: "", full_text: "" }

        Utils::IOSelector.each_line_from(
          first: first_reader,
          second: second_reader,
        ) do |tag, string_received|
          line_hash[tag] << string_received
          line_hash[:full_text] << string_received
        end
        line_hash
      end

      before { wait(1).for(subject) }

      its([:first]) { is_expected.to eq("Lorem\ndolor\n") }
      its([:second]) { is_expected.to eq("ipsum\nsit\namet\n") }

      its([:full_text]) {
        is_expected.to eq("Lorem\nipsum\ndolor\nsit\namet\n")
      }
    end

    describe "::new" do
      let(:selector) do
        Utils::IOSelector.new(
          first: first_reader,
          second: second_reader,
        )
      end
      subject { selector }

      describe "pre-read" do
        its(:pending_streams) {
          are_expected.to eq([first_reader, second_reader])
        }

        its(:separator) {
          is_expected.to eq($INPUT_RECORD_SEPARATOR)
        }
      end

      describe "post-read" do
        before do
          wait(1).for {
            subject.each_line_nonblock {}
            true
          }.to be true
        end

        after { expect(selector.all_streams).to all be_closed }

        its(:pending_streams) { are_expected.to be_empty }
        its(:separator) {
          is_expected.to eq($INPUT_RECORD_SEPARATOR)
        }
      end

      describe "#each_line_nonblock" do
        subject do
          line_hash = { first: "", second: "", full_text: "" }
          super().each_line_nonblock do |tag, string_received|
            line_hash[tag] << string_received
            line_hash[:full_text] << string_received
          end
          line_hash
        end

        before { wait(1).for(subject) }
        after { expect(selector.all_streams).to all be_closed }

        its([:first]) { is_expected.to eq("Lorem\ndolor\n") }
        its([:second]) { is_expected.to eq("ipsum\nsit\namet\n") }

        its([:full_text]) {
          is_expected.to eq("Lorem\nipsum\ndolor\nsit\namet\n")
        }
      end

      its(:all_streams) {
        are_expected.to eq([first_reader, second_reader])
      }

      its(:all_tags) { are_expected.to eq([:first, :second]) }

      describe "#tag_of" do
        subject do
          {
            "first tag" => super().tag_of(first_reader),
            "second tag" => super().tag_of(second_reader),
          }
        end

        its(["first tag"]) { is_expected.to eq(:first) }
        its(["second tag"]) { is_expected.to eq(:second) }
      end
    end

    describe "::new with a custom separator" do
      subject do
        tagged_streams = {
          first: first_reader,
          second: second_reader,
        }
        Utils::IOSelector.new(tagged_streams, ",")
      end

      its(:separator) { is_expected.to eq(",") }
    end
  end

  describe "given binary streams" do
    let(:pathname) { Pathname.new("#{TEST_FIXTURE_DIR}/test.bin") }
    let(:first_reader) { File.open(pathname) }
    let(:second_reader) { File.open(pathname) }

    describe "::each_chunk_from" do
      subject do
        blob_hash = { 0 => "".b, 1 => "".b }
        merged_bytes = []

        Utils::IOSelector.each_chunk_from(
          [first_reader, second_reader],
          0x1000,
        ) do |tag, string_received|
          blob_hash[tag] << string_received
          merged_bytes.concat(string_received.bytes)
        end

        blob_hash[:merged_blob] = merged_bytes.sort!.pack("c*")
        blob_hash
      end

      before { wait(1).for(subject) }

      its([0]) {
        is_expected
          .to eq(Array.new(0x1002) { |n| n % 0x100 }.pack("c*"))
      }

      its([1]) {
        is_expected
          .to eq(Array.new(0x1002) { |n| n % 0x100 }.pack("c*"))
      }

      its([:merged_blob]) {
        is_expected.to eq(0x1002.times
                          .flat_map { |n| [n % 0x100] * 2 }
                          .sort
                          .pack("c*"))
      }
    end

    describe "::new" do
      let(:selector) do
        Utils::IOSelector.new([first_reader, second_reader], nil)
      end
      subject { selector }

      describe "pre-read" do
        its(:pending_streams) {
          are_expected.to eq([first_reader, second_reader])
        }

        its(:separator) { is_expected.to be_nil }
      end

      describe "post-read" do
        before do
          wait(1).for {
            subject.each_chunk_nonblock(0x1234) {}
            true
          }.to be true
        end

        after { expect(selector.all_streams).to all be_closed }

        its(:pending_streams) { are_expected.to be_empty }
        its(:separator) { is_expected.to be_nil }
      end

      describe "#each_chunk_nonblock" do
        subject do
          blob_hash = { 0 => "".b, 1 => "".b }
          merged_bytes = []

          super()
            .each_chunk_nonblock(0x801) do |tag, string_received|
            blob_hash[tag] << string_received
            merged_bytes.concat(string_received.bytes)
          end

          blob_hash[:merged_blob] = merged_bytes.sort!.pack("c*")
          blob_hash
        end

        before { wait(1).for(subject) }
        after { expect(selector.all_streams).to all be_closed }

        its([0]) {
          is_expected
            .to eq(Array.new(0x1002) { |n| n % 0x100 }.pack("c*"))
        }

        its([1]) {
          is_expected
            .to eq(Array.new(0x1002) { |n| n % 0x100 }.pack("c*"))
        }

        its([:merged_blob]) {
          is_expected.to eq(0x1002.times
                            .flat_map { |n| [n % 0x100] * 2 }
                            .sort
                            .pack("c*"))
        }
      end

      its(:all_streams) {
        are_expected.to eq([first_reader, second_reader])
      }

      its(:all_tags) { are_expected.to eq([0, 1]) }

      describe "#tag_of" do
        subject do
          {
            "first tag" => super().tag_of(first_reader),
            "second tag" => super().tag_of(second_reader),
          }
        end

        its(["first tag"]) { is_expected.to eq(0) }
        its(["second tag"]) { is_expected.to eq(1) }
      end
    end
  end
end
