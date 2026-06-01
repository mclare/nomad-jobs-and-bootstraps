namespace "default" {
  variables {
    path "global/*" {
      capabilities = ["read"]
    }

    path "nomad/jobs/*" {
      capabilities = ["read"]
    }
  }
}