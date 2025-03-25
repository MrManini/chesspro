class CommandHandler:
    def __init__(self, server, game_manager, board_manager):
        self.server = server
        self.game_manager = game_manager
        self.board_manager = board_manager
        
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
                if self.game_manager.validate_move(move):
                    self.board_manager.update_remote_move(move)
                    self.server.send_game_event({'response': 'move is valid'})
                else:
                    self.server.send_game_event({'error': 'illegal move'})

            elif action == 'disconnect':
                self.server.is_connected = False
                self.server.send_game_event({'response': 'disconnected'})
                self.game_manager.end_game()
                break

            else:
                self.server.send_game_event({'error': 'invalid command'})

    def send_game_event(self, event):
        self.server.send_game_event(event)

    def ping(self):
        return {'response': 'pong'}