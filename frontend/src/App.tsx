import { BrowserRouter, Routes, Route, NavLink, Link } from 'react-router-dom'
import LandingPage from './LandingPage'
import PricingPage from './PricingPage'
import TodoPage from './TodoPage'
import './style.css'

function Navbar() {
	return (
		<nav className="navbar">
			<div className="nav-brand">
				<Link to="/">
					<span className="brand-icon">✦</span>
					<span className="brand-name">TaskFlow</span>
				</Link>
			</div>
			<div className="nav-links">
				<NavLink to="/" end className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
					Home
				</NavLink>
				<NavLink to="/pricing" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
					Pricing
				</NavLink>
				<NavLink to="/todos" className={({ isActive }) => isActive ? 'nav-link nav-cta active' : 'nav-link nav-cta'}>
					Open App →
				</NavLink>
			</div>
		</nav>
	)
}

export default function App() {
	return (
		<BrowserRouter>
			<div className="app">
				<Navbar />
				<main className="main-content">
					<Routes>
						<Route path="/" element={<LandingPage />} />
						<Route path="/pricing" element={<PricingPage />} />
						<Route path="/todos" element={<TodoPage />} />
					</Routes>
				</main>
				<footer className="footer">
					<p>
						<span className="brand-icon">✦</span> TaskFlow &nbsp;·&nbsp;
						Built with React + Express + PostgreSQL &nbsp;·&nbsp;
						<span style={{ opacity: 0.5 }}>Three-Tier Architecture on Azure AKS</span>
					</p>
				</footer>
			</div>
		</BrowserRouter>
	)
}
