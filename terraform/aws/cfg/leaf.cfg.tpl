%{if isLeaf}
SYS-URLS=[%{ for id, hh in hub ~}"nats-leaf://${sys_leaf}:${sys_psw}@${hh}:4224",%{ endfor ~}]
ACC-URLS=[%{ for id, hh in hub ~}"nats-leaf://${leaf}:${acc_psw}@${hh}:4224",%{ endfor ~}]
%{endif}

leafnodes {
no_advertise: true
%{if isLeaf}
remotes = [
		{
			urls: $SYS-URLS
			account: SYS
		},
		{
			urls: $ACC-URLS
			account: ACC
		},
	]
%{ else }
listen 0.0.0.0:4224
%{endif}
}
