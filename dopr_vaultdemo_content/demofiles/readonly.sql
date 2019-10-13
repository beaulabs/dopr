CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
REVOKE ALL ON SCHEMA public FROM public, "{{name}}";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";
GRANT USAGE ON SCHEMA thelab TO "{{name}}";
GRANT SELECT ON ALL TABLES IN SCHEMA thelab TO "{{name}}";
