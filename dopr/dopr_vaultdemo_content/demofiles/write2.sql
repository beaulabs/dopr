CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT CONNECT ON DATABASE labapp TO "{{name}}";
GRANT ALL ON labapp TO "{{name}}";
