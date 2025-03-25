from lights.lights_order import conversion_to_number
import board
import neopixel

# Configuration
LED_COUNT = 64
PIN = board.D18  # GPIO18 (PWM)

# Initialize NeoPixels
pixels = neopixel.NeoPixel(PIN, LED_COUNT, brightness=0.5, auto_write=False)

# Color Dictionary
colors = {
    'r': (255, 0, 0),
    'g': (0, 255, 0),
    'b': (0, 0, 255),
    'w': (255, 255, 255),
    'y': (255, 255, 0),
    'c': (0, 255, 255),
    'm': (255, 0, 255)
}

def set_led(input_str):
    try:
        # Extract values from input
        color_char = input_str[0] if input_str[0].isalpha() else None
        led_index = conversion_to_number(input_str[1:])
        
        # Validate index
        if led_index < 0 or (led_index > 63 and led_index != 99):
            print("Invalid LED number. Use 0-63 or 99 for all.")
            return

        # Determine color
        color = colors.get(color_char, (0, 0, 0)) if color_char else (0, 0, 0)

        # Set LEDs
        if led_index == 99:
            pixels.fill(color)
        else:
            pixels[led_index] = color
        
        pixels.show()
        print(f"LED{'s' if led_index == 99 else ''} set to {color}")

    except (ValueError, IndexError):
        print("Invalid input. Use format 'cNN', e.g., 'g32' or '99' for all.")