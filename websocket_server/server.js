const WebSocket = require('ws');
const { Client } = require('pg');
require('dotenv').config();

// Connect to PostgreSQL
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

    ws.on('message', async (message) => {
        console.log(`Received: ${message}`);
        
        try {
            const data = JSON.parse(message);
            if (data.type === 'move') {
                await db.query('UPDATE current_game SET pgn = $1 WHERE id = 1', [data.pgn]);

                // Notify both clients about the move
                clients.forEach(client => {
                    if (client.readyState === WebSocket.OPEN) {
                        client.send(JSON.stringify({ type: 'update', pgn: data.pgn }));
                    }
                });
            }
        } catch (err) {
            console.error('Error processing message:', err);
            ws.send(JSON.stringify({ type: 'error', message: 'Invalid request' }));
        }
    });

    ws.on('close', () => {
        clients = clients.filter(client => client !== ws);
        console.log(`Client disconnected (${clients.length}/2)`);
    });
});

console.log(`WebSocket server running on ws://localhost:${process.env.WS_PORT}`);