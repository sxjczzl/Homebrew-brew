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
end
