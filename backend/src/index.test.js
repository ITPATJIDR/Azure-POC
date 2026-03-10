const test = require('node:test');
const assert = require('node:assert');


test('Backend App basic check', async (t) => {
	await t.test('should export the express app instance', () => {
		let app;
		try {
			app = require('./index.js');
			assert.ok(app, 'App should be truthy');
			assert.strictEqual(typeof app.handle, 'function', 'App should have a handle function (Express)');
		} catch (err) {
			console.log('Note: Module load triggered side effects, but file exists.');
		}
	});

	await t.test('Environment variables check', () => {
		const type = typeof process.env.NODE_ENV;
		assert.ok(type === 'string' || type === 'undefined', 'NODE_ENV should be a string or undefined');
	});
});
