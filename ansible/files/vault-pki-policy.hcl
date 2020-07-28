    path "pki/issue/*" {
      capabilities = ["create", "update"]
    }

    path "pki/sign/*" {
      capabilities = ["create", "update"]
    }

    path "pki/roles/*" {
      capabilities = ["create", "update"]
    }
    path "pki/revoke" {
      capabilities = ["create", "update"]
    }

    path "pki/tidy" {
      capabilities = ["create", "update"]
    }

    path "pki*" {
      capabilities = ["read","list"]
    }
