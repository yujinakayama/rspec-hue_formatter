require 'rspec/hue_formatter'

module RSpec
  RSpec.describe HueFormatter do
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
        [:passed,  'green',  [25_000, 40_000]],
        [:pending, 'yellow', [10_000, 15_000]],
        [:failed,  'red',    [0,      5_000]]
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
  end
end
