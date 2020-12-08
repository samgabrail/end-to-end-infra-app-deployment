pid_file = "./pidfile"

vault {
  address = "http://vault.hashidemos.tekanaid.com:8200"
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
      config = {
        role_id_file_path = "/tmp/webblog_role_id"
        secret_id_file_path = "/tmp/webblog_wrapped_secret_id"
        remove_secret_id_file_after_reading = true
        secret_id_response_wrapping_path = "auth/approle/role/webblog-approle/secret-id"
    }
  }

  sink "file" {
    config = {
      path = "/tmp/vault_token"
      mode = 0644
      }
    }
}