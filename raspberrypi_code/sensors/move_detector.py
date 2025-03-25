from sensor_reader import read_adc, set_mux_channel
from sensors_order import sensors_order
import time

# Initialize previous sensor values
previous_values = [2.5] * 64
LOWER_THRESHOLD = 341
UPPER_THRESHOLD = 683

def piece_color(value):
    if value < LOWER_THRESHOLD:
        return "black"
    elif value > UPPER_THRESHOLD:
        return "white"
    else:
        return "empty"

def detect_board_changes():
    global previous_values
    current_values = []

    # Read from all sensors
    for mux in range(8):
        set_mux_channel(mux)
        for adc_channel in range(8):
            adc_value = read_adc(adc_channel)
            current_values.append(adc_value)
            time.sleep(0.001)

    # Detect changes
    leaves = []
    appears = []
    for i in range(64):
        prev = previous_values[i]
        curr = current_values[i]

        if piece_color(prev) != "empty" and piece_color(curr) == "empty":
            leaves.append(sensors_order[i])
        elif piece_color(prev) == "empty" and piece_color(curr) != "empty":
            appears.append(sensors_order[i])

    previous_values = current_values
    return leaves, appears