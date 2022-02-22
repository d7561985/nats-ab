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

    ${account}: {
        users: [
            {user: ${leaf_user}, password: ${leaf_psw}}
        ]
    },
}

system_account: SYS

# Auth for user
authorization {
    default_permissions = {
      publish = "SANDBOX.*"
      subscribe = ["PUBLIC.>", "_INBOX.>"]
    }

    ADMIN = {
      publish = ">"
      subscribe = ">"
    }

    REQUESTOR = {
        publish = ["req.a", "req.b"]
        subscribe = "_INBOX.>"
    }

    RESPONDER = {
        subscribe = ["req.a", "req.b"]
        publish = "_INBOX.>"
    }

    users: [
        {user: valera, password: valera, permissions: $ADMIN},
        {user: requestor, password: requestor, permissions: $REQUESTOR},
        {user: responder, password: responder, permissions: $RESPONDER},
    ]
}

cluster {
    # Authorization for route connections
    # Other server can connect if they supply the credentials listed here
    # This server will connect to discovered routes using this user
    authorization {
      user: ${route_user}
      password: ${route_psw}
      timeout: 0.5
    }

    listen 0.0.0.0:4223
    name ${cluster}
    routes = [
%{ for id, hh in nodes ~}
        nats-route://${route_user}:${route_psw}@${hh}:4223
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
