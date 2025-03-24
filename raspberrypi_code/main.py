from game import GameManager
from board import BoardManager
from bluetooth import CommandHandler

def main():
    game_manager = GameManager()
    board_manager = BoardManager(game_manager)
    command_handler = CommandHandler(board_manager, game_manager)
    
    command_handler.server.start_server()