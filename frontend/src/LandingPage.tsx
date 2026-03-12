import { Link } from 'react-router-dom'

export default function LandingPage() {
	return (
		<div className="page landing-page">
			{/* Hero */}
			<section className="hero">
				<div className="hero-badge">✦ Three-Tier Cloud Architecture</div>
				<h1 className="hero-title">
					Manage Taskss.<br />
					<span className="gradient-text">Ship Faster.</span>
				</h1>
				<p className="hero-sub">
					A production-grade Todo app built on Azure AKS — React frontend,
					Express API, and PostgreSQL database. Designed to showcase real-world
					three-tier architecture and calculate cloud ROI.
				</p>
				<div className="hero-cta">
					<Link to="/todos" className="btn btn-primary">
						🚀 Get Started — It's Free
					</Link>
					<Link to="/pricing" className="btn btn-ghost">
						View Pricing →
					</Link>
				</div>

				{/* Floating Stats */}
				<div className="stat-pills">
					<div className="stat-pill">
						<span className="pill-value">3</span>
						<span className="pill-label">Architecture Tiers</span>
					</div>
					<div className="stat-pill">
						<span className="pill-value">99.9%</span>
						<span className="pill-label">Uptime SLA</span>
					</div>
					<div className="stat-pill">
						<span className="pill-value">AKS</span>
						<span className="pill-label">Azure Kubernetes</span>
					</div>
					<div className="stat-pill">
						<span className="pill-value">IaC</span>
						<span className="pill-label">OpenTofu Managed</span>
					</div>
				</div>
			</section>

			{/* Architecture Diagram */}
			<section className="arch-section">
				<h2 className="section-heading">Three-Tier Architecture</h2>
				<div className="arch-grid">
					<div className="arch-card tier-1">
						<div className="tier-icon">🖥</div>
						<div className="tier-label">Tier 1</div>
						<h3>Presentation</h3>
						<p>React + Vite SPA served via Nginx. Hosted on Azure CDN for global low-latency delivery.</p>
						<div className="tech-tags">
							<span>React 18</span><span>TypeScript</span><span>Vite</span><span>Nginx</span>
						</div>
					</div>
					<div className="arch-arrow">→</div>
					<div className="arch-card tier-2">
						<div className="tier-icon">⚙️</div>
						<div className="tier-label">Tier 2</div>
						<h3>Application</h3>
						<p>Express.js REST API containerized in Docker and orchestrated by Azure Kubernetes Service (AKS).</p>
						<div className="tech-tags">
							<span>Node.js</span><span>Express</span><span>Docker</span><span>AKS</span>
						</div>
					</div>
					<div className="arch-arrow">→</div>
					<div className="arch-card tier-3">
						<div className="tier-icon">🗄</div>
						<div className="tier-label">Tier 3</div>
						<h3>Data</h3>
						<p>PostgreSQL database for persistent todo storage. Managed via Azure Database for PostgreSQL Flexible Server.</p>
						<div className="tech-tags">
							<span>PostgreSQL 16</span><span>Azure DB</span><span>ACR</span>
						</div>
					</div>
				</div>
			</section>

			{/* Features */}
			<section className="features-section">
				<h2 className="section-heading">Why TaskFlow?</h2>
				<div className="features-grid">
					{[
						{ icon: '🔐', title: 'Secure by Default', desc: 'Helmet.js, CORS, NSG rules on AKS — security baked in at every layer.' },
						{ icon: '📈', title: 'Scalable Architecture', desc: 'Kubernetes auto-scaling ensures zero downtime under variable load.' },
						{ icon: '🏗', title: 'Infrastructure as Code', desc: 'OpenTofu manages VNet, subnets, and NSGs. Reproducible on any environment.' },
						{ icon: '💰', title: 'Measurable ROI', desc: 'Clear pricing tiers and ROI calculator to justify cloud infrastructure costs.' },
						{ icon: '⚡', title: 'Fast & Responsive', desc: 'React 18 with Vite ensures sub-second page loads and smooth interactions.' },
						{ icon: '🐘', title: 'Persistent Storage', desc: 'PostgreSQL ensures your todos survive container restarts and deployments.' },
					].map(f => (
						<div className="feature-card" key={f.title}>
							<div className="feature-icon">{f.icon}</div>
							<h4>{f.title}</h4>
							<p>{f.desc}</p>
						</div>
					))}
				</div>
			</section>

			{/* CTA Banner */}
			<section className="cta-banner">
				<h2>Ready to manage your tasks in the cloud?</h2>
				<p>Start free, scale when you need. No credit card required.</p>
				<Link to="/todos" className="btn btn-primary btn-lg">
					Open Todo App →
				</Link>
			</section>
		</div>
	)
}
