import spidev
import RPi.GPIO as GPIO
import time
import os
from sensor_reader import read_adc, set_mux_channel

MUX_SELECT_PINS = [17, 27, 22]  # GPIO pins for A, B, C
NUM_MUXES = 8  # 8 muxes for 64 sensors

THRESHOLD_HIGH = 3.5  # ~4V for one polarity
THRESHOLD_LOW = 1.5   # ~1V for other polarity

# Init SPI
spi = spidev.SpiDev()
spi.open(0, 0)
spi.max_speed_hz = 1350000

# Init GPIO
GPIO.setmode(GPIO.BCM)
for pin in MUX_SELECT_PINS:
    GPIO.setup(pin, GPIO.OUT)

def detect_piece(voltage):
    if voltage > THRESHOLD_HIGH:
        return 'W'  # White piece
    elif voltage < THRESHOLD_LOW:
        return 'B'  # Black piece
    else:
        return '.'  # Empty

def clear_screen():
    os.system('clear')

def print_board(board):
    clear_screen()
    print("  A B C D E F G H")
    for i, row in enumerate(board):
        row_str = f"{8 - i} " + ' '.join(row)
        print(row_str)

try:
    while True:
        board = [['.' for _ in range(8)] for _ in range(8)]

        for mux_index in range(NUM_MUXES):
            set_mux_channel(mux_index)
            time.sleep(0.001)

            for input_index in range(8):
                voltage = read_adc(input_index)
                piece = detect_piece(voltage)

                row = mux_index
                col = input_index
                board[row][col] = piece

        print_board(board)
        time.sleep(0.5)  # Refresh rate

except KeyboardInterrupt:
    GPIO.cleanup()
    spi.close()
