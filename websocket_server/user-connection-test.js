const WebSocket = require('ws');
const jwt = require('jsonwebtoken');
const readline = require('readline');
require('dotenv').config();

const uuid1 = process.env.TEST_UUID_1;
const uuid2 = process.env.TEST_UUID_2;
const uuids = [uuid1, uuid2];
const secret = process.env.JWT_SECRET;

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

rl.question("Select user (1 or 2): ", (choice) => {

    const userUuid = uuids[choice - 1];
    const token = jwt.sign({ uuid: userUuid }, secret, { expiresIn: '1h' });
    console.log(token);

    const ws = new WebSocket(`ws://localhost:${process.env.WS_PORT}?token=${token}`);

    ws.on("open", () => {
        console.log("Connected to WebSocket server");
        console.log("Type a command and press Enter to send.");

        rl.on("line", (input) => {
            if (input.toLowerCase() === "exit") {
                console.log("Closing connection...");
                ws.close();
                rl.close();
            } else {
                ws.send(input);
            }
        });
    });

    ws.on("message", (data) => {
        console.log("Received:", data.toString());
    });

    ws.on("close", () => {
        console.log("Disconnected from server");
        rl.close();
    });

    ws.on("error", (err) => {
        console.error("WebSocket error:", err);
    });

});