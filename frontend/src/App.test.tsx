import { render, screen } from '@testing-library/react'
import { expect, test } from 'vitest'
import App from './App'

test('renders brand name TaskFlow', () => {
	render(<App />)
	const brandElement = screen.getAllByText(/TaskFlow/i)[0]
	expect(brandElement).toBeDefined()
})
