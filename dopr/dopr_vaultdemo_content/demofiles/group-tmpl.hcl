# Grant permissions on the group specific path
# The region is specified in the group metadata
path "group-kv/data/team/{{identity.groups.names.engineers.metadata.team}}/*" {
	capabilities = [ "create", "update", "read", "delete", "list" ]
}
