listen: 0.0.0.0:4222
server_name: srv-${domain}-${host}
jetstream {
    store_dir: "./s1-1"
    domain: ${domain}
}
cluster {
    listen 0.0.0.0:4223
    name cluster-hub
    routes = [
%{ for id, hh in nodes ~}
        nats-route://${hh}:4223
%{ endfor ~}
    ]
}
leafnodes {
    listen 0.0.0.0:4224
    no_advertise: true
}
mqtt {
    port: 4225
}
http: 0.0.0.0:8080
#include ./nats-account-resolver.cfg
