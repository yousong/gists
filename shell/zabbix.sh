#!/bin/bash
#
# Actions on hostgroup, host, item
#
#	https://www.zabbix.com/documentation/3.2/manual/api/reference/hostgroup
#	https://www.zabbix.com/documentation/3.2/manual/api/reference/host
#	https://www.zabbix.com/documentation/3.2/manual/api/reference/item
#
# Send metric data with zabbix sender protocol, which is different from the HTTP based RPC protocol
#
#	"ZBXD" 0x01 <8-byte-little-endian-length-of-json-payload> <json-payload>
#
# - 0x01 is the protocol version
# - json-payload has the following format
#
#		{ "request": "sender data",
#		  "data": [
#			{
#				"host": <hostid>,
#				"key": <itemname>,
#				"value": <itemvalue>,
#				"clock": <epoch>
#			}
#		  ],
#		  "clock": <epoch>
#		}
#
# - The response will have the following json data in it
#
#		{"response":"success", "info":"processed: 1331; failed: 0; total: 1331; seconds spent: 0.079761"}
#
api="http://example.com/zabbix/api_jsonrpc.php"
auth="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

curl_() {
	local d="$1"

	# The content-type header is required
	curl -H "Content-Type: application/json-rpc" -d "$d" "$api"
}

login() {
	local r='{"jsonrpc":"2.0","method":"user.login","id":1,"params":{"user": "%s", "password": "%s"}}'
	local user="Admin"
	local password="sankuai"

	r="$(printf "$r" "$user" "$password")"

	curl_ "$r"
}

hostgroup_get() {
	local r='{"jsonrpc":"2.0","method":"hostgroup.get","id":1,"auth":"%s","params":{"filter": {"name":"%s"}}}'
	local name="$1"

	r="$(printf "$r" "$auth" "$name")"
	curl_ "$r"
}

host_get() {
	local r='{"jsonrpc":"2.0","method":"host.get","id":1,"auth":"%s","params":{"output": ["hostid"],"filter": {"host":"%s"}}}'
	local name="$1"

	r="$(printf "$r" "$auth" "$name")"
	curl_ "$r"
}

item_get() {
	local r='{"jsonrpc":"2.0","method":"item.get","id":1,"auth":"%s","params":{"output": ["itemid"],"filter":{"key_":"%s"},"hostids":"%s"}}'
	local name="$1"
	local hostid="$2"

	r="$(printf "$r" "$auth" "$name" "$hostid")"
	curl_ "$r"
}

# ./z.sh login
# ./z.sh hostgroup_get "groupName"
# ./z.sh hostgroup_get "nonexistentGroupName"
# ./z.sh host_get "hostname"
# ./z.sh item_get "itemName" "hostId"
"$@"
