CREATE ROLE alice WITH LOGIN PASSWORD 'abcd1234';
GRANT ALL PRIVILEGES ON SCHEMA public TO alice;
GRANT SELECT ON transaction_analysis TO alice;