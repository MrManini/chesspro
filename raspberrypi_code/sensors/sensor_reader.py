import spidev
import RPi.GPIO as GPIO
import time

# SPI setup
spi = spidev.SpiDev()
spi.open(0, 0)  # Open SPI bus 0, chip select 0
spi.max_speed_hz = 1350000  # SPI speed

# MUX Selector GPIO pins
MUX_SELECT_PINS = [17, 27, 22]  # GPIO pins for multiplexer selectors
GPIO.setmode(GPIO.BCM)
GPIO.setup(MUX_SELECT_PINS, GPIO.OUT)

def read_adc(channel):
    """ Read SPI data from the MCP3008 (0-7 channels) """
    if channel < 0 or channel > 7:
        return -1
    adc = spi.xfer2([1, (8 + channel) << 4, 0])  # MCP3008 read command
    value = ((adc[1] & 3) << 8) | adc[2]  # Combine bytes into 10-bit value
    return value

def set_mux_channel(channel):
    """ Set the multiplexer to the desired channel using 3 GPIO pins """
    bits = [(channel >> i) & 1 for i in range(3)]
    GPIO.output(MUX_SELECT_PINS, bits)
