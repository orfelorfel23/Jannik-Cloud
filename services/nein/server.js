const http = require('http');
const fs = require('fs');
const path = require('path');

const excusesPath = path.join(__dirname, 'excuses.json');

const server = http.createServer((req, res) => {
    // Enable CORS for any client
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    
    // Only accept GET requests
    if (req.method !== 'GET') {
        res.writeHead(405);
        return res.end(JSON.stringify({ error: "Method Not Allowed" }));
    }

    try {
        // We read the file on every request so changes to excuses.json reflect instantly
        const excusesRaw = fs.readFileSync(excusesPath, 'utf8');
        const excuses = JSON.parse(excusesRaw);
        
        // Pick a random excuse
        const randomExcuse = excuses[Math.floor(Math.random() * excuses.length)];
        
        res.writeHead(200);
        res.end(JSON.stringify({ message: randomExcuse }));
    } catch (err) {
        console.error("Error reading excuses.json:", err);
        res.writeHead(500);
        res.end(JSON.stringify({ message: "Nein. (Fallback)" }));
    }
});

const PORT = 8080;
server.listen(PORT, () => {
    console.log(`No-as-a-Service API is listening on port ${PORT}`);
});
