locals {
  should_patch = lookup(local.globalSettings, "patchVaultPath", false) != false
}
data "vault_generic_secret" "vault_es_secret" {
  count = local.should_patch ? 1 : 0
  path  = local.globalSettings.patchVaultPath
}

resource "vault_generic_secret" "vault_es_update" {
  count = local.should_patch ? 1 : 0
  path  = local.globalSettings.patchVaultPath

  data_json = jsonencode(
    merge(
      jsondecode(data.vault_generic_secret.vault_es_secret[0].data_json),
      {
        (local.globalSettings.patchVaultKey) = merge(
          jsondecode(data.vault_generic_secret.vault_es_secret[0].data_json)[local.globalSettings.patchVaultKey],
          {
            (local.globalSettings.patchVaultInternalKey) = random_password.elastic_password.result
          }
        )
      }
    )
  )
  depends_on = [ random_password.elastic_password, data.vault_generic_secret.vault_es_secret ]
}

resource "vault_generic_secret" "vault_gb_es_store" {
  count = lookup(local.globalSettings, "storePassVault", false) != false ? 1 : 0
  path  = local.globalSettings.storePassVault

  data_json = jsonencode({
    elastic = random_password.elastic_password.result
  })
}
