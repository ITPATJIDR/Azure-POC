import { useEffect, useRef, useState } from 'react'

interface Todo {
	id: number
	title: string
	completed: boolean
	created_at: string
}

const API_BASE = import.meta.env.VITE_API_URL ?? ''

export default function TodoPage() {
	const [todos, setTodos] = useState<Todo[]>([])
	const [loading, setLoading] = useState(true)
	const [error, setError] = useState<string | null>(null)
	const [newTitle, setNewTitle] = useState('')
	const [adding, setAdding] = useState(false)
	const [filter, setFilter] = useState<'all' | 'active' | 'done'>('all')
	const [editingId, setEditingId] = useState<number | null>(null)
	const [editText, setEditText] = useState('')
	const inputRef = useRef<HTMLInputElement>(null)

	// ─── Fetch todos ─────────────────────────────────────────────────────────
	const fetchTodos = async () => {
		try {
			const res = await fetch(`${API_BASE}/api/todos`)
			if (!res.ok) throw new Error(`HTTP ${res.status}`)
			const data = await res.json()
			setTodos(data.todos)
			setError(null)
		} catch (e) {
			setError(e instanceof Error ? e.message : 'Failed to connect to backend')
		} finally {
			setLoading(false)
		}
	}

	useEffect(() => { fetchTodos() }, [])

	// ─── Add todo ─────────────────────────────────────────────────────────────
	const addTodo = async () => {
		const title = newTitle.trim()
		if (!title) return
		setAdding(true)
		try {
			const res = await fetch(`${API_BASE}/api/todos`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ title }),
			})
			if (!res.ok) throw new Error(`HTTP ${res.status}`)
			const todo = await res.json()
			setTodos(prev => [todo, ...prev])
			setNewTitle('')
			inputRef.current?.focus()
		} catch (e) {
			setError(e instanceof Error ? e.message : 'Failed to add todo')
		} finally {
			setAdding(false)
		}
	}

	// ─── Toggle complete ──────────────────────────────────────────────────────
	const toggleTodo = async (todo: Todo) => {
		try {
			const res = await fetch(`${API_BASE}/api/todos/${todo.id}`, {
				method: 'PUT',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ completed: !todo.completed }),
			})
			if (!res.ok) throw new Error(`HTTP ${res.status}`)
			const updated = await res.json()
			setTodos(prev => prev.map(t => t.id === updated.id ? updated : t))
		} catch (e) {
			setError(e instanceof Error ? e.message : 'Failed to update todo')
		}
	}

	// ─── Delete todo ──────────────────────────────────────────────────────────
	const deleteTodo = async (id: number) => {
		try {
			const res = await fetch(`${API_BASE}/api/todos/${id}`, { method: 'DELETE' })
			if (!res.ok) throw new Error(`HTTP ${res.status}`)
			setTodos(prev => prev.filter(t => t.id !== id))
		} catch (e) {
			setError(e instanceof Error ? e.message : 'Failed to delete todo')
		}
	}

	// ─── Edit todo ────────────────────────────────────────────────────────────
	const startEdit = (todo: Todo) => {
		setEditingId(todo.id)
		setEditText(todo.title)
	}
	const saveEdit = async (id: number) => {
		const title = editText.trim()
		if (!title) { setEditingId(null); return }
		try {
			const res = await fetch(`${API_BASE}/api/todos/${id}`, {
				method: 'PUT',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ title }),
			})
			if (!res.ok) throw new Error(`HTTP ${res.status}`)
			const updated = await res.json()
			setTodos(prev => prev.map(t => t.id === updated.id ? updated : t))
		} catch (e) {
			setError(e instanceof Error ? e.message : 'Failed to update todo')
		} finally {
			setEditingId(null)
		}
	}

	// ─── Filtered todos ───────────────────────────────────────────────────────
	const filtered = todos.filter(t => {
		if (filter === 'active') return !t.completed
		if (filter === 'done') return t.completed
		return true
	})
	const totalDone = todos.filter(t => t.completed).length
	const totalPending = todos.filter(t => !t.completed).length

	return (
		<div className="page todo-page">
			{/* Header */}
			<div className="todo-header">
				<h1 className="todo-title">
					<span className="gradient-text">My Todos</span>
				</h1>
				<div className="todo-meta">
					<span className="todo-stat">{totalPending} pending</span>
					<span className="todo-stat done">{totalDone} done</span>
					<span className="todo-stat total">{todos.length} total</span>
				</div>
			</div>

			{/* Error Banner */}
			{error && (
				<div className="error-banner">
					⚠️ {error}
					<button onClick={fetchTodos} className="btn-retry">Retry</button>
				</div>
			)}

			{/* Add Todo Input */}
			<div className="add-todo-bar">
				<input
					ref={inputRef}
					type="text"
					className="todo-input"
					placeholder="Add a new task... (Press Enter)"
					value={newTitle}
					onChange={e => setNewTitle(e.target.value)}
					onKeyDown={e => e.key === 'Enter' && addTodo()}
					disabled={adding}
				/>
				<button
					className="btn btn-primary"
					onClick={addTodo}
					disabled={adding || !newTitle.trim()}
				>
					{adding ? '…' : '+ Add'}
				</button>
			</div>

			{/* Filter Tabs */}
			<div className="filter-tabs">
				{(['all', 'active', 'done'] as const).map(f => (
					<button
						key={f}
						className={`filter-tab ${filter === f ? 'active' : ''}`}
						onClick={() => setFilter(f)}
					>
						{f === 'all' ? `All (${todos.length})` : f === 'active' ? `Active (${totalPending})` : `Done (${totalDone})`}
					</button>
				))}
			</div>

			{/* Todo List */}
			{loading ? (
				<div className="center">
					<div className="spinner" />
					<p>Loading todos from database…</p>
				</div>
			) : filtered.length === 0 ? (
				<div className="empty-state">
					<div className="empty-icon">📋</div>
					<p>{filter === 'done' ? 'No completed tasks yet.' : filter === 'active' ? 'No active tasks. Add one above!' : 'No tasks yet. Add your first task!'}</p>
				</div>
			) : (
				<ul className="todo-list">
					{filtered.map(todo => (
						<li key={todo.id} className={`todo-item ${todo.completed ? 'completed' : ''}`}>
							<button
								className={`todo-checkbox ${todo.completed ? 'checked' : ''}`}
								onClick={() => toggleTodo(todo)}
								aria-label={todo.completed ? 'Mark incomplete' : 'Mark complete'}
							>
								{todo.completed ? '✓' : ''}
							</button>

							{editingId === todo.id ? (
								<input
									autoFocus
									className="todo-edit-input"
									value={editText}
									onChange={e => setEditText(e.target.value)}
									onBlur={() => saveEdit(todo.id)}
									onKeyDown={e => {
										if (e.key === 'Enter') saveEdit(todo.id)
										if (e.key === 'Escape') setEditingId(null)
									}}
								/>
							) : (
								<span
									className="todo-text"
									onDoubleClick={() => startEdit(todo)}
									title="Double-click to edit"
								>
									{todo.title}
								</span>
							)}

							<div className="todo-actions">
								<button
									className="action-btn edit-btn"
									onClick={() => startEdit(todo)}
									title="Edit"
								>✏️</button>
								<button
									className="action-btn delete-btn"
									onClick={() => deleteTodo(todo.id)}
									title="Delete"
								>🗑</button>
							</div>
						</li>
					))}
				</ul>
			)}

			{/* Footer hint */}
			{todos.length > 0 && (
				<p className="todo-hint">
					Todos are stored in <strong>PostgreSQL</strong> via Express REST API — three-tier architecture ✦
				</p>
			)}
		</div>
	)
}
