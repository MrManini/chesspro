import chess
import chess.engine

class GameManager:
    def __init__(self, on_game_event):
        self.board = None
        self.game_mode = None
        self.is_game_active = False
        self.on_game_event = on_game_event

    def set_game_mode(self, mode):
        if not self.is_game_active:
            self.game_mode = mode
            return True
        return False

    def start_game(self):
        if self.game_mode and not self.is_game_active:
            self.is_game_active = True
            self.board = chess.Board()
            self.print_board()
            return True
        return False

    def print_board(self):
        print(self.board)

    def move(self, move):
        if (
            not self.board.is_game_over() and 
            chess.Move.from_uci(move) in self.board.legal_moves
        ):
            chess_move = chess.Move.from_uci(move)
            self.board.push(chess_move)
            self.print_board()
            if (self.board.is_game_over()):
                self.notify_game_end(self.board.result())
            return True
        return False
    
    def get_legal_moves(self, square):
        legal_moves = [move for move in self.board.legal_moves if move.from_square == square]
        return [move.uci() for move in legal_moves]

    def validate_move(self, start, end):
        try:
            move = chess.Move.from_uci(f"{start}{end}")
            if move in self.board.legal_moves:
                self.board.push(move)
                print(f"Move played: {move.uci()}")
                return True
            print("Invalid move.")
            return False
        except Exception as e:
            print(f"Error validating move: {e}")
            return False

    def end_game(self):
        self.is_game_active = False
        self.board = None
        self.game_mode = None
    
    def is_game_over(self):
        return self.board.is_game_over()
    
    def get_result(self):
        return self.board.result()

    def notify_game_end(self, result):
            if self.on_game_event:
                self.on_game_event({'event': 'game_ended', 'result': result})