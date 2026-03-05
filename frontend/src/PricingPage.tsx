import { useState } from 'react'
import { Link } from 'react-router-dom'

const plans = [
	{
		name: 'Free',
		price: 0,
		unit: '/mo',
		color: 'plan-free',
		badge: '',
		features: [
			'Up to 50 todos',
			'1 user',
			'Basic REST API access',
			'Community support',
			'Shared PostgreSQL instance',
		],
		missing: ['Custom domain', 'SLA guarantee', 'Analytics dashboard', 'Priority support'],
		cta: 'Get Started Free',
		href: '/todos',
	},
	{
		name: 'Pro',
		price: 490,
		unit: '/mo',
		color: 'plan-pro',
		badge: '⭐ Most Popular',
		features: [
			'Unlimited todos',
			'Up to 10 users',
			'Dedicated API pod (AKS)',
			'Custom domain + SSL',
			'99.9% uptime SLA',
			'Dedicated PostgreSQL Flex Server',
			'Email support (< 24h)',
		],
		missing: ['Analytics dashboard', 'Priority support'],
		cta: 'Start Pro Trial',
		href: '/todos',
	},
	{
		name: 'Enterprise',
		price: 2490,
		unit: '/mo',
		color: 'plan-enterprise',
		badge: '🏢 Enterprise',
		features: [
			'Unlimited todos',
			'Unlimited users',
			'Private AKS cluster + VNet',
			'Custom domain + SSL',
			'99.99% uptime SLA',
			'HA PostgreSQL with read replicas',
			'Azure Monitor + Dashboards',
			'Dedicated support (< 4h SLA)',
			'OpenTofu IaC templates included',
		],
		missing: [],
		cta: 'Contact Sales',
		href: '/todos',
	},
]


export default function PricingPage() {
	return (
		<div className="page pricing-page">
			<div className="pricing-hero">
				<h1>Simple, Transparent Pricing</h1>
				<p>เลือกแผนที่เหมาะกับทีมคุณ ยกเลิกได้ทุกเวลา</p>
			</div>

			<div className="plans-grid">
				{plans.map(plan => (
					<div className={`plan-card ${plan.color} ${plan.badge ? 'plan-featured' : ''}`} key={plan.name}>
						{plan.badge && <div className="plan-badge">{plan.badge}</div>}
						<div className="plan-name">{plan.name}</div>
						<div className="plan-price">
							{plan.price === 0 ? (
								<span className="price-amount">Free</span>
							) : (
								<>
									<span className="price-currency">฿</span>
									<span className="price-amount">{plan.price.toLocaleString()}</span>
									<span className="price-unit">{plan.unit}</span>
								</>
							)}
						</div>

						<ul className="plan-features">
							{plan.features.map(f => (
								<li key={f} className="feature-item yes">✓ {f}</li>
							))}
							{plan.missing.map(f => (
								<li key={f} className="feature-item no">✗ {f}</li>
							))}
						</ul>

						<Link to={plan.href} className={`btn ${plan.badge ? 'btn-primary' : 'btn-ghost'} plan-btn`}>
							{plan.cta}
						</Link>
					</div>
				))}
			</div>

			{/* FAQ */}
			<section className="faq-section">
				<h2 className="section-heading">คำถามที่พบบ่อย</h2>
				<div className="faq-grid">
					{[
						{ q: 'ทดลองใช้ฟรีได้กี่วัน?', a: 'Pro และ Enterprise มี free trial 14 วัน ไม่ต้องใส่บัตรเครดิต' },
						{ q: 'Data อยู่ที่ไหน?', a: 'เก็บบน Azure Database for PostgreSQL ใน Region Southeast Asia (Singapore)' },
						{ q: 'Upgrade/Downgrade ได้ไหม?', a: 'ได้เลย เปลี่ยนแผนได้ทุกเวลา ไม่มีค่าปรับ' },
						{ q: 'Infrastructure ใช้อะไร?', a: 'Azure AKS + ACR + VNet managed by OpenTofu (IaC) ทุกอย่างเป็น code' },
					].map(({ q, a }) => (
						<div className="faq-card" key={q}>
							<h4>{q}</h4>
							<p>{a}</p>
						</div>
					))}
				</div>
			</section>
		</div>
	)
}
