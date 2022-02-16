HUB-URLS=[
%{ for id, hh in hub ~}
        "nats-leaf://${hh}:4224",
%{ endfor ~}
]

leafnodes {
no_advertise: true
    remotes = [
		{
			urls: $HUB-URLS
			account: ADECCNBUEBWZ727OMBFSN7OMK2FPYRM52TJS25TFQWYS76NPOJBN3KU4
 			credentials: keys/creds/OP/SYS/sys.creds
		},
		{
			urls: $HUB-URLS
			account: AA5C56FAETBTUCYM7NC5BFBYFTKLOABIOIFPQDHO4RUEAPSN3FTY5R4G
			credentials: keys/creds/OP/TEST/leaf.creds
		},
	]
}
