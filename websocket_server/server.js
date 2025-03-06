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

let clients = [];

wss.on('connection', (ws) => {
    if (clients.length >= 2) {
        ws.send(JSON.stringify({ type: 'error', message: 'Server full' }));
        ws.close();
        return;
    }

    clients.push(ws);
    console.log(`Client connected (${clients.length}/2)`);

    ws.send(JSON.stringify({ type: 'info', message: `You are client #${clients.length}` }));

    ws.on('message', async (message) => {
        try {
            const data = JSON.parse(message);
            if (data.command === "white_move") {
                await handleWhiteMove(ws, data.move);
            } else if (data.command === "black_move") {
                await handleBlackMove(ws, data.move);
            } else if (data.command === "reset") {
                await resetGame(ws);
            }
        } catch (error) {
            console.error("Error handling message:", error);
        }
    });

    ws.on('close', () => {
        clients = clients.filter(client => client !== ws);
        console.log(`Client disconnected (${clients.length}/2)`);
    });
});

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

async function resetGame(ws) {
    await db.query('TRUNCATE TABLE current_game RESTART IDENTITY');
    broadcastGameState();
}

console.log(`WebSocket server running on ws://localhost:${process.env.WS_PORT}`);