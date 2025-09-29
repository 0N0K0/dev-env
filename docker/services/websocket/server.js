const express = require('express');
const http = require('http');
const cors = require('cors');
const path = require('path');

const app = express();
const server = http.createServer(app);

// Configuration CORS
app.use(
	cors({
		origin: ['http://localhost', 'http://localhost:80'],
		credentials: true,
	})
);

// Servir les fichiers statiques (pour test.html)
app.use(express.static(__dirname));

const PORT = process.env.PORT || 3001;
const WEBSOCKET_TYPE = process.env.WEBSOCKET_TYPE || 'socketio';

console.log(`🚀 Démarrage du serveur WebSocket (type: ${WEBSOCKET_TYPE})`);

if (WEBSOCKET_TYPE === 'socketio') {
	// Configuration Socket.IO
	const { Server } = require('socket.io');
	const io = new Server(server, {
		cors: {
			origin: ['http://localhost', 'http://localhost:80'],
			methods: ['GET', 'POST'],
		},
	});

	io.on('connection', (socket) => {
		console.log('📡 Client connecté via Socket.IO:', socket.id);

		// Événement de test
		socket.emit('welcome', {
			message: 'Bienvenue sur le serveur Socket.IO!',
			timestamp: new Date().toISOString(),
		});

		// Écouter les messages du client
		socket.on('message', (data) => {
			console.log('📨 Message reçu:', data);
			// Diffuser à tous les clients connectés
			io.emit('broadcast', {
				from: socket.id,
				message: data,
				timestamp: new Date().toISOString(),
			});
		});

		// Événement de test pour la base de données
		socket.on('db_test', async () => {
			const dbInfo = {
				type: process.env.DB_TYPE,
				host: process.env.DB_HOST,
				name: process.env.DB_NAME,
				status: 'connected', // Simulé pour l'instant
			};
			socket.emit('db_response', dbInfo);
		});

		socket.on('disconnect', () => {
			console.log('📡 Client déconnecté:', socket.id);
		});
	});
} else if (WEBSOCKET_TYPE === 'native') {
	// Configuration WebSocket natif
	const WebSocket = require('ws');
	const wss = new WebSocket.Server({ server });

	wss.on('connection', (ws) => {
		console.log('📡 Client connecté via WebSocket natif');

		// Message de bienvenue
		ws.send(
			JSON.stringify({
				type: 'welcome',
				message: 'Bienvenue sur le serveur WebSocket natif!',
				timestamp: new Date().toISOString(),
			})
		);

		ws.on('message', (data) => {
			console.log('📨 Message reçu:', data.toString());

			try {
				const message = JSON.parse(data);

				// Diffuser à tous les clients connectés
				wss.clients.forEach((client) => {
					if (client.readyState === WebSocket.OPEN) {
						client.send(
							JSON.stringify({
								type: 'broadcast',
								message: message,
								timestamp: new Date().toISOString(),
							})
						);
					}
				});
			} catch (error) {
				console.error('❌ Erreur parsing message:', error);
			}
		});

		ws.on('close', () => {
			console.log('📡 Client déconnecté');
		});
	});
}

// Route de santé
app.get('/health', (req, res) => {
	res.json({
		status: 'OK',
		type: WEBSOCKET_TYPE,
		timestamp: new Date().toISOString(),
	});
});

// Route d'information
app.get('/', (req, res) => {
	res.json({
		service: 'WebSocket Server',
		type: WEBSOCKET_TYPE,
		port: PORT,
		endpoints: {
			health: '/health',
			websocket: WEBSOCKET_TYPE === 'socketio' ? '/socket.io/' : 'ws://localhost:3001',
		},
	});
});

server.listen(PORT, () => {
	console.log(`✅ Serveur WebSocket (${WEBSOCKET_TYPE}) démarré sur le port ${PORT}`);
	console.log(`🌐 Interface disponible sur http://localhost:${PORT}`);
});
