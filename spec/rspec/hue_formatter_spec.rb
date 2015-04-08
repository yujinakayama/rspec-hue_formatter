require 'rspec/hue_formatter'

module RSpec
  RSpec.describe HueFormatter do
    green_hue_range = [25_000, 40_000]
    yellow_hue_range = [10_000, 15_000]
    red_hue_range = [0, 5_000]

    subject(:formatter) do
      described_class.new(output)
    end

    let(:output) do
      StringIO.new
    end

    let(:lights) do
      3.times.map do |index|
        instance_double(Hue::Light, "light #{index + 1}").as_null_object
      end
    end

    before do
      allow(formatter).to receive(:lights).and_return(lights)
    end

    def run_example(result = :passed)
      formatter.example_started(double('notification'))
      formatter.send("example_#{result}", double('notification'))
    end

    describe 'light ordering' do
      context 'on first example' do
        it 'flashes the first light' do
          expect(lights.first).to receive(:set_state).with(a_hash_including(on: true), 0)
          run_example
        end
      end

      context 'on second example' do
        before do
          run_example
        end

        it 'shuts off the first light and flashes the second light' do
          expect(lights[0]).to receive(:set_state).with(a_hash_including(on: false), 0)
          expect(lights[1]).to receive(:set_state).with(a_hash_including(on: true), 0)
          run_example
        end
      end

      context 'after running examples the same number lights' do
        before do
          lights.size.times do
            run_example
          end
        end

        it 'shuts off the last light and flashes the first light' do
          expect(lights.last).to receive(:set_state).with(a_hash_including(on: false), 0)
          expect(lights.first).to receive(:set_state).with(a_hash_including(on: true), 0)
          run_example
        end
      end
    end

    describe 'light coloring' do
      [
        [:passed,  'green',  green_hue_range],
        [:pending, 'yellow', yellow_hue_range],
        [:failed,  'red',    red_hue_range]
      ].each do |result, color, hue_range|
        context "when example #{result}" do
          it "flashes the current light in #{color}" do
            expect(lights.first).to receive(:set_state).with(
              a_hash_including(hue: a_value_between(*hue_range)),
              0
            )

            run_example(result)
          end
        end
      end
    end

    describe '#dump_summary' do
      let(:notification) do
        Core::Notifications::SummaryNotification.new(
          duration,
          examples,
          failed_examples,
          pending_examples,
          load_time
        )
      end

      let(:duration)  { 1.0 }
      let(:examples) { example_count.times.map { double('example') } }
      let(:failed_examples) { examples.sample(failure_count) }
      let(:pending_examples) { examples.sample(pending_count) }
      let(:load_time) { 0.1 }

      let(:example_count) { 0 }
      let(:failure_count) { 0 }
      let(:pending_count) { 0 }

      before do
        allow(formatter).to receive(:sleep)
      end

      it 'turns all the lights off once and then turns them on' do
        lights.each do |light|
          expect(light).to receive(:set_state).with(a_hash_including(on: false), anything).ordered
        end

        lights.each do |light|
          expect(light).to receive(:set_state).with(a_hash_including(on: true), anything).ordered
        end

        formatter.dump_summary(notification)
      end

      shared_examples 'turns all the lights' do |color, hue_range|
        it "turns all the lights on in #{color}" do
          lights.each do |light|
            expect(light).to receive(:set_state).with(
              a_hash_including(hue: a_value_between(*hue_range)),
              anything
            )
          end

          formatter.dump_summary(notification)
        end
      end

      context 'when no examples were run' do
        let(:example_count) { 0 }
        include_examples 'turns all the lights', 'green', green_hue_range
      end

      context 'when all examples were passed' do
        let(:example_count) { 3 }
        include_examples 'turns all the lights', 'green', green_hue_range
      end

      context 'when an example was failed' do
        let(:example_count) { 3 }
        let(:failure_count) { 1 }
        include_examples 'turns all the lights', 'red', red_hue_range
      end

      context 'when an example was pending' do
        let(:example_count) { 3 }
        let(:pending_count) { 1 }
        include_examples 'turns all the lights', 'yellow', yellow_hue_range
      end

      context 'when an example was failed and another example was pending' do
        let(:example_count) { 3 }
        let(:failure_count) { 1 }
        let(:pending_count) { 1 }
        include_examples 'turns all the lights', 'red', red_hue_range
      end
    end
  end
end
