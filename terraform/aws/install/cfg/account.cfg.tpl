accounts: {
    SYS: {
        users: [
            {user: ${sys_user}, password: ${sys_psw}}
            {user: ${sys_leaf}, password: ${sys_psw}, allowed_connection_types: ["LEAFNODE"]}
        ]
    }
  # Service
    NOTIFICATION = {
        users = [
          {user: 'myservice', password: ${acc_psw}}
          {user: 'backend', password: ${acc_psw}}
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

  GITOPS = {
      publish = ["$JS.API.STREAM.CREATE.*", "$JS.API.STREAM.UPDATE.*", "$JS.API.STREAM.DELETE.*",
       "$JS.API.STREAM.INFO.*", "$JS.API.STREAM.LIST", "$JS.API.STREAM.NAMES", "$JS.API.CONSUMER.DURABLE.CREATE.*.*",
       "$JS.API.CONSUMER.DELETE.*.*", "$JS.API.CONSUMER.INFO.*.*","$JS.API.CONSUMER.LIST.*","$JS.API.CONSUMER.NAMES.*",
       "$JS.API.STREAM.TEMPLATE.>"]
      subscribe = "_INBOX.>"
  }

  CLIENT = {
    publish = {
        deny: ["$JS.API.STREAM.CREATE.*", "$JS.API.STREAM.UPDATE.*", "$JS.API.STREAM.DELETE.*",
               "$JS.API.CONSUMER.DURABLE.CREATE.*.*", "$JS.API.CONSUMER.DELETE.*.*", "$JS.API.STREAM.TEMPLATE.>"]
    }
  }

  ACC = {
    users = [
      {user: ${js_admin}, password: ${acc_psw}, permissions: $GITOPS}
      {user: ${admin}, password: ${acc_psw}}
      {user: ${leaf}, password: ${acc_psw}, allowed_connection_types: ["LEAFNODE"]}
      {user: ${client}, password: ${acc_psw}, permissions: $CLIENT}
      {user: ${public}, password: ${acc_psw}, permissions: $CLIENT, allowed_connection_types: ["WEBSOCKET","MQTT"]}
    ]
    jetstream = enabled
  }
}

system_account: SYS