require 'hue'

module RSpec
  class HueFormatter
    Core::Formatters.register(
      self,
      :example_started, :example_passed, :example_pending, :example_failed
    )

    GREEN  = 29_000
    YELLOW = 12_750
    RED    = 0

    IMMEDIATE_TRANSITION = 0

    attr_reader :example_index

    def initialize(_output)
      @example_index = -1
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

    private

    def flash_current_light(hue)
      previous_light.set_state({ on: false }, IMMEDIATE_TRANSITION)

      state = {
                on: true,
               hue: hue,
        saturation: Hue::Light::SATURATION_RANGE.end,
        brightness: Hue::Light::BRIGHTNESS_RANGE.end
      }

      current_light.set_state(state, IMMEDIATE_TRANSITION)
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
