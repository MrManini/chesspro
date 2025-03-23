from sensor_reader import read_adc, set_mux_channel
import time

# Initialize previous sensor values
previous_values = [0] * 64
LOWER_THRESHOLD = 341
UPPER_THRESHOLD = 683

def piece_color(value):
    if value < LOWER_THRESHOLD:
        return "black"
    elif value > UPPER_THRESHOLD:
        return "white"
    else:
        return "empty"

def detect_changes():
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
            leaves.append(i)
        elif piece_color(prev) == "empty" and piece_color(curr) != "empty":
            appears.append(i)

    previous_values = current_values
    return classify_move(leaves, appears)

def classify_move(leaves, appears):
    if len(leaves) == 1 and len(appears) == 1:
        return f"Regular move from {leaves[0]} to {appears[0]}"

    elif len(leaves) == 1 and len(appears) == 1 and previous_values[appears[0]] > 0:
        return f"Capture move from {leaves[0]} to {appears[0]}"

    elif len(leaves) == 2 and len(appears) == 2:
        return f"Castling detected: {leaves} to {appears}"

    elif len(leaves) == 2 and len(appears) == 1:
        return f"En Passant detected from {leaves[0]} and {leaves[1]} to {appears[0]}"

    else:
        return "Unknown or illegal move detected"
