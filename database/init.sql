-- ─────────────────────────────────────────────────────────────────────────────
--  Todo List App — Database Initialization
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS todos (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(500) NOT NULL,
    completed   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed some sample todos
INSERT INTO todos (title, completed) VALUES
    ('Set up three-tier architecture on Azure AKS', false),
    ('Configure PostgreSQL on Kubernetes', false),
    ('Deploy frontend to Azure CDN', false),
    ('Write infrastructure as code with OpenTofu', true),
    ('Configure NSG rules for AKS cluster', true);
