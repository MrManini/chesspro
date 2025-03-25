from sensors import detect_board_changes
from lights import set_led
from movement import move_physical_piece

class BoardManager:
    def __init__(self, game_manager):
        self.game_manager = game_manager
        self.lifted_square = None
        self.held_move = None

    def update_board(self):
        leaves, appears = detect_board_changes()

        if self.held_move:
            start, end = self.held_move[:2], self.held_move[2:]

            # Check if the expected move is made
            if len(leaves) == 1 and len(appears) == 1 and leaves[0] == int(start) and appears[0] == int(end):
                print("Remote move completed successfully.")
                self.game_manager.validate_move(start, end)
                self.clear_lights()
                self.held_move = None
            else:
                print("Invalid move! Please complete the remote move.")
                set_led(f"r{start}")
                set_led(f"r{end}")
            return

        if len(leaves) == 1 and len(appears) == 0:
            # Piece lifted
            self.lifted_square = leaves[0]
            self.show_legal_moves(self.lifted_square)

        elif len(leaves) == 0 and len(appears) == 1 and self.lifted_square is not None:
            # Piece placed
            self.validate_move(self.lifted_square, appears[0])
            self.lifted_square = None

    def update_remote_move(self, move):
        self.held_move = move
        start, end = move[:2], move[2:]
        set_led(f"g{start}")
        set_led(f"g{end}")
        move_physical_piece(start, end)

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
