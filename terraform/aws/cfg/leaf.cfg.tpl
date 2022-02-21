HUB-URLS=[
%{ for id, hh in hub ~}
        "nats-leaf://${leaf_user}:${leaf_psw}@${hh}:4224",
%{ endfor ~}
]

leafnodes {
no_advertise: true
    remotes = [
		{
			urls: $HUB-URLS
			account: SYS
# 			credentials: keys/creds/OP/SYS/sys.creds
		},
		{
			urls: $HUB-URLS
			account: xxx
#			credentials: keys/creds/OP/TEST/leaf.creds
		},
	]
}
