import time
import board
import neopixel

# LED strip configuration
LED_COUNT = 64       # Number of LED pixels
LED_PIN = board.D18  # GPIO pin connected to the pixels (PWM capable pin)
LED_BRIGHTNESS = 0.5 # Brightness (0.0 to 1.0)

# Initialize NeoPixel strip
pixels = neopixel.NeoPixel(LED_PIN, LED_COUNT, brightness=LED_BRIGHTNESS, auto_write=False)

def cycle_colors():
    colors = [
        (255, 0, 0), (255, 165, 0), (255, 255, 0), (0, 255, 0), 
        (0, 255, 255), (0, 0, 255), (128, 0, 128), (255, 0, 255), 
        (255, 255, 255)  # Full spectrum colors including white
    ]
    while True:
        for color in colors:
            for brightness in [x / 10.0 for x in range(1, 11)]:  # Loop through brightness levels 0.1 to 1.0
                pixels.brightness = brightness
                pixels.fill(color)
                pixels.show()
                time.sleep(0.2)  # Small delay for smooth transition

try:
    cycle_colors()
except KeyboardInterrupt:
    pixels.fill((0, 0, 0))  # Turn off LEDs on exit
    pixels.show()