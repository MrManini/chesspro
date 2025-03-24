from sensors import detect_board_changes
from lights import set_led

class BoardManager:
    def __init__(self, game_manager):
        self.game_manager = game_manager
        self.lifted_square = None

    def update_board(self):
        leaves, appears = detect_board_changes()

        if len(leaves) == 1 and len(appears) == 0:
            # Piece lifted
            self.lifted_square = leaves[0]
            self.show_legal_moves(self.lifted_square)

        elif len(leaves) == 0 and len(appears) == 1 and self.lifted_square is not None:
            # Piece placed
            self.validate_move(self.lifted_square, appears[0])
            self.lifted_square = None

    def show_legal_moves(self, square):
        legal_moves = self.game_manager.get_legal_moves(square)
        print(f"Legal moves for {square}: {legal_moves}")
        self.clear_lights()
        for move in legal_moves:
            set_led(f"c{move[2:]}")  # Highlight legal moves

    def validate_move(self, start, end):
        is_valid = self.game_manager.validate_move(start, end)

        if is_valid:
            print("Move accepted")
            self.clear_lights()
        else:
            print("Illegal move!")
            set_led(f"r{start}")
            set_led(f"r{end}")

    def clear_lights(self):
        self.clear_lights()
