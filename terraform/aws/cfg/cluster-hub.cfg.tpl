listen: 0.0.0.0:4222
server_name: srv-${domain}-${host}
jetstream {
    store_dir: "./s1-1"
    domain: ${domain}
}

accounts: {
    SYS: {
        users: [
            {user: ${sys_user}, password: ${sys_psw}}
        ]
    }
  # Service
  NOTIFICATION = {
    users = [
      {user: 'myservice', password: 'myservice'}
      {user: 'backend', password: 'backend'}
    ]
    jetstream = {
      max_mem: 24M
      max_file: 1G
      max_streams: 5
      max_consumers: 5
    }
    exports = [
      {stream: someTopic1.>}
    ]
  }
  ADMIN = {
    users = [
      {user: ${testUser}, password: ${testPsw}}
    ]
    imports = [
      {stream: {subject: someTopic1.>, account: NOTIFICATION}}
    ]
    jetstream = enabled
  }
    xxx: {
        users: [
            {user: ${leaf_user}, password: ${leaf_psw}}
        ]
    },
}

system_account: SYS

cluster {
    # Authorization for route connections
    # Other server can connect if they supply the credentials listed here
    # This server will connect to discovered routes using this user
    authorization {
      user: ${cluster_user}
      password: ${cluster_psw}
      timeout: 0.5
    }

    listen 0.0.0.0:4223
    name ${cluster}
    routes = [
%{ for id, hh in nodes ~}
        nats-route://${cluster_user}:${cluster_psw}@${hh}:4223
%{ endfor ~}
    ]
}

%{if isHub}
leafnodes {
    listen 0.0.0.0:4224
    no_advertise: true
    authorization {
        user: ${leaf_user}
        password: ${leaf_psw}
        account: SYS
    }
}
%{endif}

mqtt {
    port: 4225
}
http: 0.0.0.0:8080
#include ./nats-account-resolver.cfg

%{if !isHub}
include ./${leafConf}
%{endif}
