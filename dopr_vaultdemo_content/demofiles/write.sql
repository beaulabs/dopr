CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
REVOKE ALL ON SCHEMA public FROM public, "{{name}}"
GRANT CONNECT ON DATABASE labapp TO "{{name}}";
GRANT USAGE ON SCHEMA thelab TO "{{name}}";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA thelab TO "{{name}}";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA thelab to "{{name}}";