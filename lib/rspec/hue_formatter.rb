require 'hue'

module RSpec
  class HueFormatter
    Core::Formatters.register(
      self,
      :start,
      :example_started, :example_passed, :example_pending, :example_failed,
      :dump_summary, :close
    )

    GREEN  = 29_000
    YELLOW = 12_750
    RED    = 0

    IMMEDIATE_TRANSITION = 0
    SLOW_TRANSITION = 10

    LIGHT_SETTERS_BY_READER = {
             on?: :on,
             hue: :hue,
      saturation: :saturation,
      brightness: :brightness
    }

    attr_reader :example_index

    def initialize(_output)
      @example_index = -1
    end

    def start(_notification)
      save_light_states
      turn_off_lights
      sleep 2
    end

    def example_started(_notification)
      @example_index += 1
    end

    def example_passed(_notification)
      flash_current_light(GREEN)
    end

    def example_pending(_notification)
      flash_current_light(YELLOW)
    end

    def example_failed(_notification)
      flash_current_light(RED)
    end

    def dump_summary(notification)
      turn_off_lights

      sleep 2

      hue = case
            when notification.failure_count.nonzero? then RED
            when notification.pending_count.nonzero? then YELLOW
            else GREEN
            end

      glow_all_lights(hue, 2)
    end

    def close(_notification)
      restore_light_states
    end

    private

    def save_light_states
      @states = lights.map do |light|
        LIGHT_SETTERS_BY_READER.each_with_object({}) do |(attr, key), state|
          state[key] = light.send(attr)
        end
      end
    end

    def restore_light_states
      lights.zip(@states).each do |light, state|
        light.set_state(state, SLOW_TRANSITION)
      end
    end

    def turn_off_lights
      set_all_light_states({ on: false }, SLOW_TRANSITION)
    end

    def glow_all_lights(hue, number_of_times)
      number_of_times.times do
        set_all_light_states(bright_state(hue), SLOW_TRANSITION)
        sleep 1
        set_all_light_states({ brightness: Hue::Light::BRIGHTNESS_RANGE.begin }, SLOW_TRANSITION)
        sleep 1
      end
    end

    def set_all_light_states(state, transition_time)
      lights.each do |light|
        light.set_state(state, transition_time)
      end
    end

    def flash_current_light(hue)
      previous_light.set_state({ on: false }, IMMEDIATE_TRANSITION)
      current_light.set_state(bright_state(hue), IMMEDIATE_TRANSITION)
    end

    def bright_state(hue)
      {
                on: true,
               hue: hue,
        saturation: Hue::Light::SATURATION_RANGE.end,
        brightness: Hue::Light::BRIGHTNESS_RANGE.end
      }
    end

    def current_light
      light_for_index(example_index)
    end

    def previous_light
      light_for_index(example_index - 1)
    end

    def light_for_index(index)
      light_index = index % lights.count
      lights[light_index]
    end

    def lights
      @lights ||= begin
        hue = Hue::Client.new
        hue.lights.sort_by(&:name)
      end
    end
  end
end
