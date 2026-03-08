const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3001;
const VERSION = process.env.APP_VERSION || '1.0.0';

// ─── Database ─────────────────────────────────────────────────────────────────
const pool = new Pool({
	host: process.env.DB_HOST || 'localhost',
	port: Number(process.env.DB_PORT) || 5432,
	database: process.env.DB_NAME || 'tododb',
	user: process.env.DB_USER || 'todouser',
	password: process.env.DB_PASSWORD || 'todopassword',
});

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
	origin: process.env.CORS_ORIGIN || '*',
	methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
}));
app.use(morgan('combined'));
app.use(express.json());

const startTime = Date.now();

// ─── Routes ──────────────────────────────────────────────────────────────────

// Health check
app.get('/health', async (req, res) => {
	const uptimeMs = Date.now() - startTime;
	let dbStatus = 'ok';
	try {
		await pool.query('SELECT 1');
	} catch {
		dbStatus = 'error';
	}
	res.json({
		status: 'ok',
		service: 'todo-backend',
		version: VERSION,
		uptime_seconds: Math.floor(uptimeMs / 1000),
		database: dbStatus,
		timestamp: new Date().toISOString(),
	});
});

// GET all todos
app.get('/api/todos', async (req, res) => {
	try {
		const result = await pool.query(
			'SELECT * FROM todos ORDER BY created_at DESC'
		);
		res.json({ total: result.rowCount, todos: result.rows });
	} catch (err) {
		console.error('GET /api/todos error:', err);
		res.status(500).json({ error: 'Database error', details: err.message });
	}
});

// POST create todo
app.post('/api/todos', async (req, res) => {
	const { title } = req.body;
	if (!title || typeof title !== 'string' || title.trim() === '') {
		return res.status(400).json({ error: 'title is required' });
	}
	try {
		const result = await pool.query(
			'INSERT INTO todos (title) VALUES ($1) RETURNING *',
			[title.trim()]
		);
		res.status(201).json(result.rows[0]);
	} catch (err) {
		console.error('POST /api/todos error:', err);
		res.status(500).json({ error: 'Database error', details: err.message });
	}
});

// PUT toggle completed / update title
app.put('/api/todos/:id', async (req, res) => {
	const id = Number(req.params.id);
	if (isNaN(id)) return res.status(400).json({ error: 'Invalid id' });

	const { completed, title } = req.body;
	try {
		let result;
		if (typeof completed === 'boolean' && title !== undefined) {
			result = await pool.query(
				'UPDATE todos SET completed = $1, title = $2 WHERE id = $3 RETURNING *',
				[completed, title.trim(), id]
			);
		} else if (typeof completed === 'boolean') {
			result = await pool.query(
				'UPDATE todos SET completed = $1 WHERE id = $2 RETURNING *',
				[completed, id]
			);
		} else if (title !== undefined) {
			result = await pool.query(
				'UPDATE todos SET title = $1 WHERE id = $2 RETURNING *',
				[title.trim(), id]
			);
		} else {
			return res.status(400).json({ error: 'Nothing to update' });
		}

		if (result.rowCount === 0) {
			return res.status(404).json({ error: 'Todo not found' });
		}
		res.json(result.rows[0]);
	} catch (err) {
		console.error('PUT /api/todos/:id error:', err);
		res.status(500).json({ error: 'Database error', details: err.message });
	}
});

// DELETE todo
app.delete('/api/todos/:id', async (req, res) => {
	const id = Number(req.params.id);
	if (isNaN(id)) return res.status(400).json({ error: 'Invalid id' });

	try {
		const result = await pool.query(
			'DELETE FROM todos WHERE id = $1 RETURNING *',
			[id]
		);
		if (result.rowCount === 0) {
			return res.status(404).json({ error: 'Todo not found' });
		}
		res.json({ message: 'Todo deleted', todo: result.rows[0] });
	} catch (err) {
		console.error('DELETE /api/todos/:id error:', err);
		res.status(500).json({ error: 'Database error', details: err.message });
	}
});

// 404 fallback
app.use((req, res) => {
	res.status(404).json({ error: 'Route not found' });
});

// ─── Start Server ─────────────────────────────────────────────────────────────
if (require.main === module) {
	app.listen(PORT, () => {
		console.log(`✅ Todo Backend running on port ${PORT}`);
		console.log(`   Health: http://localhost:${PORT}/health`);
		console.log(`   Todos:  http://localhost:${PORT}/api/todos`);
		console.log(`   DB:     ${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 5432}`);
	});
}

module.exports = app;
