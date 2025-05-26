const WebSocket = require('ws');
const fs = require('fs');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASS,
    port: 5432,
    ssl: {
        require: true,
        rejectUnauthorized: true,
        ca: fs.readFileSync('/etc/ssl/certs/us-east-2-bundle.pem').toString(), 
    }
});

const wss = new WebSocket.Server({ port: process.env.WS_PORT });

let clients = new Set();
let admin = null;
let gamemode = null;
let isGameOngoing = false;
let player1 = null;
let player2 = null;
let player1Color = 'random';
let player2Color = null;
let lastUsernameConnected = null;

wss.on('connection', async (ws, req) => {
    const token = new URL(req.url, `http://localhost`).searchParams.get('token');
    const isAdmin = new URL(req.url, `http://localhost`).searchParams.get('isAdmin') === 'true';
    if (!token) {
        ws.close();
        return;
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
        const user = await pool.query('SELECT * FROM users where uuid = $1', [decoded.uuid]);
        if (user.rows.length === 0) {
            ws.close();
            return;
        }

        if (isAdmin) {
            if (!admin) {
                admin = ws;
                ws.send(JSON.stringify({type: "role", role: "admin"}));
            } else {
                ws.send(JSON.stringify({type: "role", role: "spectator"}));
            }
        } else {
            ws.send(JSON.stringify({type: "role", role: "guest"}));
        }

        // Store username on the ws object
        ws.lastUsernameConnected = user.rows[0].username;

        // Notify all clients about the new user
        wss.clients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(JSON.stringify({
                    type: "user_connected",
                    username: ws.lastUsernameConnected
                }));
            }
        });

        // Build the list of all connected usernames except the current ws
        const clientUsernames = [];
        for (const client of wss.clients) {
            if (client.readyState === WebSocket.OPEN && client.lastUsernameConnected) {
                clientUsernames.push(client.lastUsernameConnected);
            }
        }
        // Send the list to the newly connected user
        ws.send(JSON.stringify({
            type: "player_list",
            clients: clientUsernames
        }));
        console.log(`Sent ${clientUsernames} to ${ws.lastUsernameConnected}`);
    } catch (error) {
        console.log(`Closed connection due to error: ${error}`);
        ws.close();
        return;
    }

    if (admin && gamemode === 'pvp' && player2 === null) {
        ws.send(JSON.stringify({type: "role", role: "player2"}));
    } else {
        ws.send(JSON.stringify({type: "role", role: "spectator"}));
    }

    sendGameState(ws);
    clients.add(ws);
    console.log(`Client (${lastUsernameConnected}) connected (${clients.size} total)`);

    ws.send(JSON.stringify({ type: 'info', message: `You are client #${clients.size}` }));

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
                    console.log(`Game started in mode: ${gamemode}`);
                    wss.clients.forEach((client) => {
                        if (client.readyState === WebSocket.OPEN) {
                            client.send(JSON.stringify({ type: "game_started", mode: gamemode }));
                        }
                    });
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

    ws.on('error', (error) => {
        console.error(`WebSocket error for ${ws.lastUsernameConnected}:`, error);
        ws.close();
    });

    ws.on('close', () => {
        // Notify all clients about the user disconnecting
        wss.clients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN && ws.lastUsernameConnected) {
                client.send(JSON.stringify({
                    type: "user_disconnected",
                    username: ws.lastUsernameConnected
                }));
            }
        });
        clients.delete(ws);
        if (ws === admin) {
            admin = null;
            if (clients.size > 0) transferAdmin(clients[0]);
        }
        if (ws === player1) {
            player1 = null;
            // TODO end game from disconnection
        }
        if (ws === player2){
            player2 = null;
        }
        console.log(`Client disconnected (${clients.size} total)`);
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
    console.log(`Game mode set to: ${gamemode}`);
}

function sendGameState(ws) {
    pool.query('SELECT * FROM current_game ORDER BY move ASC')
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
    pool.query('SELECT * FROM current_game ORDER BY move ASC')
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
    const lastMove = await pool.query('SELECT * FROM current_game ORDER BY move DESC LIMIT 1');

    // If there's already an unresponded white move, prevent another one
    if (lastMove.rows.length > 0 && lastMove.rows[0].black_halfmove === null) {
        ws.send(JSON.stringify({ error: "Wait for Black to move!" }));
        return;
    }

    // Insert white move
    await pool.query('INSERT INTO current_game (white_halfmove) VALUES ($1)', [whiteMove]);
    broadcastGameState();
}

async function handleBlackMove(ws, blackMove) {
    const lastMove = await pool.query('SELECT * FROM current_game ORDER BY move DESC LIMIT 1');

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
    await pool.query('UPDATE current_game SET black_halfmove = $1 WHERE move = $2', [blackMove, lastMove.rows[0].move]);
    broadcastGameState();
}

async function getPGN(gameResult) {
    // Get all moves from the current_game table
    const queryResult = await pool.query("SELECT * FROM current_game ORDER BY move");

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
    await pool.query("TRUNCATE TABLE current_game RESTART IDENTITY")
        .then(() => console.log("Game reset"))
        .catch(console.error);
}

console.log(`WebSocket server running on ws://localhost:${process.env.WS_PORT}`);