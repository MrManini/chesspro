import bluetooth
import json

class BluetoothServer:
    def __init__(self):
        self.server_socket = None
        self.client_socket = None
        self.is_connected = False

    def start_server(self, port=1):
        try:
            self.server_socket = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
            self.server_socket.bind(("", port))
            self.server_socket.listen(1)
            print("Waiting for Bluetooth connection...")

            while True:
                try:
                    self.client_socket, address = self.server_socket.accept()
                    print(f"Connected to {address}")
                    self.is_connected = True
                    break
                except Exception as e:
                    print(f"Connection failed. Retrying... Error: {e}")
        except Exception as e:
            print(f"Failed to start Bluetooth server: {e}")

    def receive_command(self):
        try:
            data = self.client_socket.recv(1024).decode('utf-8')
            if not data:
                return None
            return json.loads(data)
        except json.JSONDecodeError as e:
            print(f"Invalid JSON received: {e}")
        except Exception as e:
            print(f"Error receiving data: {e}")
        return None
    
    def send_response(self, response_data):
        try:
            response_json = json.dumps(response_data)
            self.client_socket.send(response_json.encode('utf-8'))
        except Exception as e:
            print(f"Error sending response: {e}")

    def stop_server(self):
        if self.client_socket:
            self.client_socket.close()
        if self.server_socket:
            self.server_socket.close()
        print("Bluetooth server stopped.")
