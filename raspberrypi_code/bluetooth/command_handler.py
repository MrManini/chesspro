from chess_engine import GameManager

class CommandHandler:
    def __init__(self, server):
        self.server = server
        self.game_manager = GameManager()
        
    def handle_commands(self):
        while self.server.is_connected:
            command = self.server.receive_command()
            action = command['action']

            if action == 'ping':
                response = self.ping()
                self.server.send_game_event(response)

            elif action == 'select_gamemode':
                mode = command['mode']
                if self.game_manager.set_game_mode(mode):
                    self.server.send_game_event({'success': f'game mode set to {mode}'})
                else:
                    self.server.send_game_event({'error': 'game already active'})

            elif action == 'start_game':
                if (self.game_manager.start_game()):
                    self.server.send_game_event({'response': 'game started'})
                else:
                    self.server.send_game_event({'error': 'failed to start game'})

            elif action == 'move':
                move = command['move']
                if self.game_manager.move(move):
                    self.server.send_game_event({'response': 'move successful'})
                else:
                    self.server.send_game_event({'error': 'illegal move'})

            elif action == 'disconnect':
                self.server.is_connected = False
                self.server.send_game_event({'response': 'disconnected'})
                self.game_manager.end_game()
                break

            else:
                self.server.send_game_event({'response': 'invalid command'})


    def send_game_event(self, event):
        self.server.send_game_event(event)

    def ping(self):
        return {'response': 'pong'}