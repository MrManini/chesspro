const WebSocket = require('ws');
const { Client } = require('pg');
require('dotenv').config();

const db = new Client({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    port: 5432,
});
db.connect();

const wss = new WebSocket.Server({ port: process.env.WS_PORT });

let clients = new Set();
let admin = null;
let gamemode = null;
let isGameOngoing = false;
let player1 = null;
let player2 = null;
let player1Color = 'random';
let player2Color = null;

wss.on('connection', (ws) => {
    if (!admin) {
        admin = ws;
        ws.send(JSON.stringify({type: "role", role: "admin"}));
    } else if (admin && gamemode === 'pvp' && player2 === null) {
        ws.send(JSON.stringify({type: "role", role: "player2"}));
    } else {
        ws.send(JSON.stringify({type: "role", role: "spectator"}));
    }

    sendGameState(ws);
    clients.add(ws);
    console.log(`Client connected (${clients.length} total)`);

    ws.send(JSON.stringify({ type: 'info', message: `You are client #${clients.length}` }));

    ws.on('message', async (message) => {
        try {
            const data = JSON.parse(message);
            // Admin-specific commands
            if (ws === admin) {
                if (data.command === "admin.set_mode" && !isGameOngoing) {
                    setGameMode(data.mode);
                }
                if (data.command === "admin.set_color" && !isGameOngoing) {
                    setColor(data.color);
                }
                if (data.command === "admin.start_game" && isGameReady()) {
                    await resetGame();
                    setColor(player1Color);
                    isGameOngoing = true;
                }
                if (data.command === "admin.transfer_admin") {
                    transferAdmin(data.targetWs);
                }
            }
            // Player-specific commands
            if (ws === player1 && isGameOngoing) {
                if (player1Color === "white" && data.command === "white_move") {
                    await handleWhiteMove(ws, data.move);
                } else if (player1Color === "black" && data.command === "black_move") {
                    await handleBlackMove(ws, data.move);
                }
            } else if (ws === player2 && isGameOngoing) {
                if (player2Color === "white" && data.command === "white_move") {
                    await handleWhiteMove(ws, data.move);
                } else if (player2Color === "black" && data.command === "black_move") {
                    await handleBlackMove(ws, data.move);
                }
            }
        } catch (error) {
            console.error("Error handling message:", error);
        }
    });

    ws.on('close', () => {
        clients.delete(ws);
        if (ws === admin) {
            admin = null;
            if (clients.length > 0) transferAdmin(clients[0]);
        }
        if (ws === player1) {
            player1 = null;
            // TODO end game from disconnection
        }
        if (ws === player2){
            player2 = null;
        }
        console.log(`Client disconnected (${clients.length} total)`);
    });
});

function transferAdmin(targetWs) {
    if (wss.clients.has(targetWs)) {
        admin = targetWs;
        admin.send(JSON.stringify({ type: "role", role: "admin" }));
    }
}

function setGameMode(mode) {
    gamemode = mode;
    if (mode === "pvp") {
        const clients = Array.from(wss.clients);
        player1 = admin;
        player1.send(JSON.stringify({ type: "role", role: "player1" }));
        player2 = clients.find((ws) => ws !== admin);
        if (player2) {
            player2.send(JSON.stringify({ type: "role", role: "player2" }));
        }
    } else if (mode === "pvb") {
        player1 = admin;
        player1.send(JSON.stringify({ type: "role", role: "player1" }));
        player2 = null;
    } else if (mode === "bvb") {
        player1 = null;
        player2 = null;
    }
}

function sendGameState(ws) {
    db.query('SELECT * FROM current_game ORDER BY move ASC')
        .then((result) => {
            ws.send(JSON.stringify({ type: "game_state", gameState: result.rows }));
        })
        .catch((err) => console.error("Error sending game state:", err));
}

function setColor(color) {
    if (!["white", "black", "random"].includes(color)) {
        return { success: false, message: "Invalid color choice. Use 'white', 'black', or 'random'." };
    }

    if (color === "random") {
        color = Math.random() < 0.5 ? "white" : "black";
    }

    player1Color = color;
    player2Color = color === "white" ? "black" : "white";
}

function isGameReady() {
    if (gamemode === 'pvp') {
        return !isGameOngoing && player1 && player2;
    } else if (gamemode === 'pvb') {
        return !isGameOngoing && player1;
    } else if (gamemode === 'bvb') {
        return !isGameOngoing;
    }
    return false;
}

function broadcastGameState() {
    db.query('SELECT * FROM current_game ORDER BY move ASC')
        .then((result) => {
            const gameState = result.rows;
            wss.clients.forEach((client) => {
                if (client.readyState === WebSocket.OPEN) {
                    client.send(JSON.stringify({ type: "game_state", gameState }));
                }
            });
        })
        .catch((err) => console.error("Error broadcasting game state:", err));
}

async function handleWhiteMove(ws, whiteMove) {
    const lastMove = await db.query('SELECT * FROM current_game ORDER BY move DESC LIMIT 1');

    // If there's already an unresponded white move, prevent another one
    if (lastMove.rows.length > 0 && lastMove.rows[0].black_halfmove === null) {
        ws.send(JSON.stringify({ error: "Wait for Black to move!" }));
        return;
    }

    // Insert white move
    await db.query('INSERT INTO current_game (white_halfmove) VALUES ($1)', [whiteMove]);
    broadcastGameState();
}

async function handleBlackMove(ws, blackMove) {
    const lastMove = await db.query('SELECT * FROM current_game ORDER BY move DESC LIMIT 1');

    // If there's no previous white move, Black cannot play
    if (lastMove.rows.length === 0) {
        ws.send(JSON.stringify({ error: "White must move first!" }));
        return;
    }

    // If Black already moved in the last row, prevent another Black move
    if (lastMove.rows[0].black_halfmove !== null) {
        ws.send(JSON.stringify({ error: "Wait for White to move!" }));
        return;
    }

    // Update last row with Black's move
    await db.query('UPDATE current_game SET black_halfmove = $1 WHERE move = $2', [blackMove, lastMove.rows[0].move]);
    broadcastGameState();
}

async function getPGN(gameResult) {
    // Get all moves from the current_game table
    const queryResult = await db.query("SELECT * FROM current_game ORDER BY move");

    // Convert moves into PGN format
    let pgn = "";
    queryResult.rows.forEach(row => {
        pgn += `${row.move}.${row.white_halfmove || ''} ${row.black_halfmove || ''} `;
    });

    if (gameResult === 'WHITE_WIN') pgn += '1-0';
    if (gameResult === 'BLACK_WIN') pgn += '0-1';
    if (gameResult === 'DRAW' || gameResult === 'STALEMATE') pgn += '1/2-1/2';

    return pgn;
}

async function endGame(reason, result) {
    console.log(`Game ended: ${reason}`)
    isGameOngoing = false;
    player1 = null;
    player2 = null;
    let pgn = await getPGN(result);

}

async function resetGame(ws) {
    await db.query("TRUNCATE TABLE current_game RESTART IDENTITY")
        .then(() => console.log("Game reset"))
        .catch(console.error);
}

console.log(`WebSocket server running on ws://localhost:${process.env.WS_PORT}`);