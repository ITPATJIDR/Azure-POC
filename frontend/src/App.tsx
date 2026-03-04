import { useEffect, useState } from 'react'
import './style.css'

// ─── Types ─────────────────────────────────────────────────────────────────
interface Item {
	id: number
	name: string
	category: string
	status: 'active' | 'maintenance' | 'inactive'
	stock: number
}

interface Stats {
	total_services: number
	active: number
	maintenance: number
	inactive: number
	total_stock: number
}

interface Health {
	status: string
	service: string
	version: string
	uptime_seconds: number
}

// ─── Helper ────────────────────────────────────────────────────────────────
const API_BASE = import.meta.env.VITE_API_URL ?? ''

function formatUptime(seconds: number): string {
	const h = Math.floor(seconds / 3600)
	const m = Math.floor((seconds % 3600) / 60)
	const s = seconds % 60
	if (h > 0) return `${h}h ${m}m`
	if (m > 0) return `${m}m ${s}s`
	return `${s}s`
}

// ─── App ───────────────────────────────────────────────────────────────────
export default function App() {
	const [items, setItems] = useState<Item[]>([])
	const [stats, setStats] = useState<Stats | null>(null)
	const [health, setHealth] = useState<Health | null>(null)
	const [loading, setLoading] = useState(true)
	const [error, setError] = useState<string | null>(null)
	const [healthStatus, setHealthStatus] = useState<'loading' | 'ok' | 'err'>('loading')

	useEffect(() => {
		const fetchAll = async () => {
			try {
				const [itemsRes, statsRes, healthRes] = await Promise.all([
					fetch(`${API_BASE}/api/items`),
					fetch(`${API_BASE}/api/stats`),
					fetch(`${API_BASE}/health`),
				])

				if (!itemsRes.ok || !statsRes.ok || !healthRes.ok) {
					throw new Error('One or more API requests failed')
				}

				const itemsData = await itemsRes.json()
				const statsData = await statsRes.json()
				const healthData = await healthRes.json()

				setItems(itemsData.items)
				setStats(statsData)
				setHealth(healthData)
				setHealthStatus('ok')
			} catch (e) {
				setError(e instanceof Error ? e.message : 'Failed to connect to backend')
				setHealthStatus('err')
			} finally {
				setLoading(false)
			}
		}

		fetchAll()
		// Poll health every 30s
		const interval = setInterval(async () => {
			try {
				const res = await fetch(`${API_BASE}/health`)
				const data = await res.json()
				setHealth(data)
				setHealthStatus('ok')
			} catch {
				setHealthStatus('err')
			}
		}, 30_000)

		return () => clearInterval(interval)
	}, [])

	return (
		<div className="app">
			{/* ── Header ── */}
			<header className="header">
				<div className="header-left">
					<h1>🚀 SCG Services Dashboard</h1>
					<p>DevOps Take-Home Assignment — Phase 1</p>
				</div>

				<div className={`health-badge ${healthStatus}`}>
					<span className={`dot ${healthStatus === 'ok' ? 'pulse' : ''}`} />
					{healthStatus === 'loading' && 'Connecting…'}
					{healthStatus === 'ok' && (
						<span>
							Backend OK &nbsp;·&nbsp; v{health?.version} &nbsp;·&nbsp; up {formatUptime(health?.uptime_seconds ?? 0)}
						</span>
					)}
					{healthStatus === 'err' && 'Backend Unreachable'}
				</div>
			</header>

			{/* ── Stats ── */}
			{stats && (
				<div className="stats-grid">
					{[
						{ label: 'Total Services', value: stats.total_services },
						{ label: 'Active', value: stats.active },
						{ label: 'Maintenance', value: stats.maintenance },
						{ label: 'Inactive', value: stats.inactive },
						{ label: 'Total Stock', value: stats.total_stock.toLocaleString() },
					].map(({ label, value }) => (
						<div className="stat-card" key={label}>
							<div className="stat-label">{label}</div>
							<div className="stat-value">{value}</div>
						</div>
					))}
				</div>
			)}

			{/* ── Items Table ── */}
			<p className="section-title">Service Inventory</p>

			{loading && (
				<div className="center">
					<div className="spinner" />
					<p>Loading services…</p>
				</div>
			)}

			{error && (
				<div className="center">
					<p style={{ color: 'var(--red)', fontWeight: 600 }}>⚠️ {error}</p>
					<p style={{ marginTop: 8, fontSize: '0.85rem' }}>
						Make sure the backend is running on port 3001.
					</p>
				</div>
			)}

			{!loading && !error && (
				<div className="table-wrapper">
					<table>
						<thead>
							<tr>
								<th>#</th>
								<th>Name</th>
								<th>Category</th>
								<th>Status</th>
								<th>Stock</th>
							</tr>
						</thead>
						<tbody>
							{items.map((item) => (
								<tr key={item.id}>
									<td style={{ color: 'var(--text-muted)' }}>{item.id}</td>
									<td style={{ fontWeight: 500 }}>{item.name}</td>
									<td style={{ color: 'var(--text-muted)' }}>{item.category}</td>
									<td>
										<span className={`badge ${item.status}`}>
											{item.status === 'active' && '●'}
											{item.status === 'maintenance' && '◐'}
											{item.status === 'inactive' && '○'}
											{' '}{item.status}
										</span>
									</td>
									<td>{item.stock.toLocaleString()}</td>
								</tr>
							))}
						</tbody>
					</table>
				</div>
			)}

			{/* ── Footer ── */}
			<footer className="footer">
				<p>SCG DevOps Challenge · Built with React + Vite + Express</p>
			</footer>
		</div>
	)
}
