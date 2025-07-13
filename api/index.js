import express from 'express';
const app = express();

app.get('/', (req, res) => {
	res.json({ message: 'Hello from Node.js' });
});

app.listen(80);
