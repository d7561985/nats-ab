listen: 0.0.0.0:4222
http: 0.0.0.0:8080
server_name: srv-${domain}-${host}

jetstream {
    store_dir: "./data"
    domain: ${domain}
    #max_mem: 8G
    #max_file: 8G
}

cluster {
    listen 0.0.0.0:4223
    name ${cluster}

    # if under loadbalancer - true, no balancer = false
    no_advertise = true

    # Authorization for route connections
    # Other server can connect if they supply the credentials listed here
    # This server will connect to discovered routes using this user
    authorization {
      user: "${cluster_user}"
      password: "${protocols_pwd}"
      timeout: 0.5
    }

    routes = [
%{ for id, hh in nodes ~}
        nats-route://${cluster_user}:${protocols_pwd}@${hh}:4223
%{ endfor ~}
    ]
}

# Gateways enable connecting one or more clusters together into a full mesh
#gateway {
#  name: ${cluster}
#  port: 7222
#  authorization {
#    user: ${gw_user}
#    password: ${protocols_pwd}
#    timeout: 0.75
#  }
#  gateways: [
#%{ for id, hub in cluster_nodes ~}
#  {name: "${id}", urls: [%{ for hh in hub ~}"nats://${gw_user}:${protocols_pwd}@${hh}:7222",%{ endfor ~}]},
#%{ endfor ~}
#  ]
#}

mqtt {
    port: 4225
}

# Required TLS configuration
websocket{
    port: 433
    no_tls: true
}

include ./leaf.conf
include ./account.conf
#include ./nats-account-resolver.cfg

