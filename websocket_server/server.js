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

    ws.on('close', () => {
        clients = clients.filter(client => client !== ws);
        console.log(`Client disconnected (${clients.length}/2)`);
    });
});

console.log(`WebSocket server running on ws://localhost:${process.env.WS_PORT}`);