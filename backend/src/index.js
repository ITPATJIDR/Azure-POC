const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3001;
const VERSION = process.env.APP_VERSION || '1.0.0';

// ─── Middleware ──────────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
	origin: process.env.CORS_ORIGIN || '*',
	methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
}));
app.use(morgan('combined'));
app.use(express.json());

const startTime = Date.now();

// ─── Sample Data ─────────────────────────────────────────────────────────────
const items = [
	{ id: 1, name: 'SCG Cement', category: 'Building Materials', status: 'active', stock: 1250 },
	{ id: 2, name: 'SCG Packaging', category: 'Packaging', status: 'active', stock: 860 },
	{ id: 3, name: 'SCG Chemicals', category: 'Chemicals', status: 'maintenance', stock: 430 },
	{ id: 4, name: 'SCG Distribution', category: 'Logistics', status: 'active', stock: 2100 },
	{ id: 5, name: 'SCG Trading', category: 'Trading', status: 'inactive', stock: 0 },
];

// ─── Routes ──────────────────────────────────────────────────────────────────

// Health check
app.get('/health', (req, res) => {
	const uptimeMs = Date.now() - startTime;
	res.json({
		status: 'ok',
		service: 'scg-backend',
		version: VERSION,
		uptime_seconds: Math.floor(uptimeMs / 1000),
		timestamp: new Date().toISOString(),
	});
});

// API Status
app.get('/api/status', (req, res) => {
	res.json({
		api_version: 'v1',
		environment: process.env.NODE_ENV || 'development',
		message: 'SCG Backend API is running 🚀',
	});
});

// List all items
app.get('/api/items', (req, res) => {
	const { status } = req.query;
	const filtered = status ? items.filter(i => i.status === status) : items;
	res.json({
		total: filtered.length,
		items: filtered,
	});
});

// Get item by ID
app.get('/api/items/:id', (req, res) => {
	const item = items.find(i => i.id === Number(req.params.id));
	if (!item) {
		return res.status(404).json({ error: 'Item not found' });
	}
	res.json(item);
});

// Stats summary
app.get('/api/stats', (req, res) => {
	const active = items.filter(i => i.status === 'active').length;
	const maintenance = items.filter(i => i.status === 'maintenance').length;
	const inactive = items.filter(i => i.status === 'inactive').length;
	const totalStock = items.reduce((sum, i) => sum + i.stock, 0);

	res.json({
		total_services: items.length,
		active,
		maintenance,
		inactive,
		total_stock: totalStock,
	});
});

// 404 fallback
app.use((req, res) => {
	res.status(404).json({ error: 'Route not found' });
});

// ─── Start Server ─────────────────────────────────────────────────────────────
app.listen(PORT, () => {
	console.log(`✅ Backend server running on port ${PORT}`);
	console.log(`   Health: http://localhost:${PORT}/health`);
	console.log(`   API:    http://localhost:${PORT}/api/items`);
});

module.exports = app;
