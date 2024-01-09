locals {
  domain    = "gitlab.regemini.com"
  namespace = "gitlab"
  gitlab_values = {
    global = {
      edition       = "ce"
      shell = {
        port = 2224
        hostKeys = {
          secret = "gitlab-ssh-host-keys"
        }
      },
      pod = {
        labels = {
          node-pool = "gitlab"
        }
      },
      antiAffinity = "hard",
      affinity = {
        podAntiAffinity = {
          node-pool = "gitlab"
        }
      },
      email = {
        display_name = "GitLab",
        from         = "gitlab@geminiadvisory.io",
        reply_to     = "noreply@gitlab.regemini.com"
        #subject_suffix = ""
      },
      smtp = {
        address             = "smtp.gmail.com",
        authentication      = "login",
        domain              = "smtp.gmail.com",
        enabled             = true,
        openssl_verify_mode = "peer",
        port                = 587,
        starttls_auto       = true
        pool                = false
        user_name           = "gitlab@geminiadvisory.io"
        password = {
          secret = "gitlab-smtp-password"
          key    = "password"
        }
      },
      hosts = {
        domain     = "regemini.com"
        hostSuffix = "gitlab"
        https      = true
        gitlab = {
          name  = "gitlab.regemini.com"
          https = true
        }
        ssh = "gitlab.regemini.com"
      },
      ingress = {
        enabled              = false
        configureCertmanager = false
      },
      minio = {
        enabled = false
      },
      kas = {
        enabled = true
      },
      appConfig = {
        omniauth = {
          enabled                 = false
          autoSignInWithProvider  = ""
          syncProfileFromProvider = "[]"
          syncProfileAttributes   = "['email']"
          allowSingleSignOn       = "['saml']"
          blockAutoCreatedUsers   = true
          autoLinkLdapUser        = false
          autoLinkSamlUser        = false
          autoLinkUser            = "['saml']"
          externalProviders       = "[]"
          allowBypassTwoFactor    = "[]"
          providers               = "[]"
        }
        backups = {
          bucket    = "gitlab-backup-orbital-wording"
          tmpBucket = "gitlab-tmp-orbital-wording"
        }
        object_store = {
          enabled = true
          connection = {
            secret = "gitlab-object-storage"
            key    = "connection"
          }
        }
        lfs = {
          bucket     = "gitlab-lfs-orbital-wording"
          connection = {}
        }
        artifacts = {
          bucket     = "gitlab-artifacts-orbital-wording"
          connection = {}
        }
        uploads = {
          bucket     = "gitlab-uploads-orbital-wording"
          connection = {}
        }
        packages = {
          bucket     = "gitlab-packages-orbital-wording"
          connection = {}
        }
        externalDiffs = {
          bucket     = "gitlab-external-diffs-orbital-wording"
          connection = {}
        }
        dependencyProxy = {
          enabled    = true
          bucket     = "gitlab-dependency-proxy-orbital-wording"
          connection = {}
        }
        terraformState = {
          enabled    = false
          bucket     = "gitlab-terraform-state-orbital-wording"
          connection = {}
        }
        ciSecureFiles = {
          enabled    = true
          bucket     = "gitlab-ci-secure-files-orbital-wording"
          connection = {
            secret = "gitlab-object-storage"
            key    = "connection"
          }
        }
      }
    },
    certmanager = {
      install = false
    }
    nginx-ingress = {
      enabled = false
    },
    registry = {
      enabled = true
    },
    gitlab = {
      webservice = {
        minReplicas = 1
        resources = {
          limits = {
            cpu    = "4"
            memory = "6G"
          }
          requests = {
            cpu    = "500m"
            memory = "900M"
          }
        }
        annotations = {
          es_logs_enabled = "true"
          es_logs_json_error_key = "true"
        }
      }
      workhorse = {
        resources = {
          limits = {
            cpu    = "3"
            memory = "4G"
          }
          requests = {
            cpu    = "400m"
            memory = "500M"
          }
        }
      }
      pages = {
        enabled = false
      }
      sidekiq = {
        enabled     = true
        minReplicas = 1
        resources = {
          limits = {
            cpu    = "3"
            memory = "2.5G"
          }
          requests = {
            cpu    = "200m"
            memory = "600M"
          }
        }
      }
      gitlab-grafana = {
        enabled = false
      },
      praefect = {
        enabled = true
      }
      gitlab-shell = {
        minReplicas = 1
        service = {
          internalPort = 2224
        }
        annotations = {
          es_logs_enabled = "true"
          es_logs_json_error_key = "true"
        }
      }
      toolbox = {
        persistence = {
          enabled = true
          size    = "15Gi"
        }
        backups = {
          bucket    = "gitlab-backup-orbital-wording"
          tmpBucket = "gitlab-tmp-orbital-wording"
          objectStorage = {
            backend = "gcs"
            config = {
              gcpProject = "orbital-wording-233917"
              secret     = "gitlab-backup-storage-config"
              key        = "config"
            }
          }
          cron = {
            enabled   = true
            schedule  = "0 0 * * *"
            extraArgs = "--skip uploads,artifacts,lfs"
            persistence = {
              enabled    = false
              accessMode = "ReadWriteOnce"
              size       = "10Gi"
            }
          }
        }
      }
    },
    redis = {
      resources = {
        requests = {
          cpu    = "20m"
          memory = "64Mi"
        }
      }
    }
    prometheus = {
      install = false
    },
    gitlab-runner = {
      install      = false
      name         = "gitlab-red-runner"
      pull_secrets = "harbor"
      rbac = {
        create = true
      }
      concurrent      = 4
      check_interval  = 0
      session_timeout = 1800
      image           = "alpine:3.16.1"
      cache = {
        minio_url   = "minio.t.regemini.io:443"
        bucket      = "ardent-rarity-239115-gitlab-tmp"
        path        = "/cache/"
        shared      = true
        secret_name = "minio"
      }
    }
  }
}
