# F3.2 · Mapping de GitHub Ocean (alojada por Port) como código (ADR 0016-0018).
# La integración se instaló a mano en el paso 07 SIN recursos por defecto; aquí se adopta y se le
# da el mapping. Solo ve los repos donde está instalada la GitHub App de Port.
#
# Identificadores que usan los pipelines (F3.4) para enlazar el linaje — no cambiarlos a la ligera:
#   githubPullRequest  <repo>-<número>        p. ej. platform-gitops-9, meridian-orders-12
#   release            <repo>-<tag>           p. ej. meridian-orders-v0.1.0
#   githubWorkflowRun  <repo>-<id de la ejecución>
locals {
  # Qué repos son "servicios" del catálogo (platform-gitops es plataforma, no un servicio)
  service_repos_jq = "[\"meridian-orders\"]"
  service_of_repo  = "(.__repository as $r | if (${local.service_repos_jq} | index($r)) then $r else null end)"

  # Horas entre dos fechas ISO 8601 (null si falta la segunda), con dos decimales
  hours_between = "(((%s | sub(\"\\\\.[0-9]+Z$\"; \"Z\") | fromdateiso8601) - (%s | sub(\"\\\\.[0-9]+Z$\"; \"Z\") | fromdateiso8601)) / 3600 * 100 | floor / 100)"

  github_ocean_resources = [
    {
      kind     = "organization"
      selector = { query = "true" }
      port = { entity = { mappings = {
        identifier = ".login"
        title      = ".login"
        blueprint  = "\"githubOrganization\""
        properties = {
          login       = ".login"
          id          = ".id"
          url         = ".html_url"
          avatarUrl   = ".avatar_url"
          description = ".description // \"\""
          publicRepos = ".public_repos"
          createdAt   = ".created_at"
          updatedAt   = ".updated_at"
        }
      } } }
    },
    {
      kind = "repository"
      selector = {
        query         = "true"
        includedFiles = ["README.md", "CODEOWNERS", ".gitignore", ".github/pull_request_template.md"]
      }
      port = { entity = { mappings = {
        identifier = ".name"
        title      = ".name"
        blueprint  = "\"githubRepository\""
        properties = {
          description   = ".description // \"\""
          visibility    = "if .private then \"private\" else \"public\" end"
          defaultBranch = ".default_branch"
          url           = ".html_url"
          language      = ".language // \"\""
          last_push     = ".pushed_at"
          readme        = ".__includedFiles[\"README.md\"]"
          codeowners    = ".__includedFiles[\"CODEOWNERS\"]"
          gitignore     = ".__includedFiles[\".gitignore\"]"
          pr_template   = ".__includedFiles[\".github/pull_request_template.md\"]"
        }
      } } }
    },
    {
      # El mismo repo, visto como servicio del catálogo (solo los de service_repos_jq)
      kind     = "repository"
      selector = { query = ".name as $n | (${local.service_repos_jq} | index($n)) != null" }
      port = { entity = { mappings = {
        identifier = ".name"
        title      = ".name"
        blueprint  = "\"service\""
        relations = {
          github_repository = ".name"
        }
      } } }
    },
    {
      kind = "pull-request"
      selector = {
        query  = "true"
        states = ["open", "closed"]
        since  = 90 # días
      }
      port = { entity = { mappings = {
        identifier = ".__repository + \"-\" + (.number | tostring)"
        title      = ".title"
        blueprint  = "\"githubPullRequest\""
        properties = {
          status           = "if .merged_at then \"merged\" else .state end"
          prNumber         = ".number"
          link             = ".html_url"
          branch           = ".head.ref"
          createdAt        = ".created_at"
          closedAt         = ".closed_at"
          mergedAt         = ".merged_at"
          has_reviewers    = "(.requested_reviewers // [] | length) > 0"
          has_assignees    = "(.assignees // [] | length) > 0"
          cycle_time_hours = "if .merged_at then ${format(local.hours_between, ".merged_at", ".created_at")} else null end"
          lead_time_hours  = "if .merged_at then ${format(local.hours_between, ".merged_at", ".created_at")} else null end"
        }
        relations = {
          repository      = ".__repository"
          service         = local.service_of_repo
          git_hub_creator = ".user.login | gsub(\"\\\\[\"; \"-\") | gsub(\"\\\\]$\"; \"\")"
        }
      } } }
    },
    {
      kind     = "release"
      selector = { query = "true" }
      port = { entity = { mappings = {
        identifier = ".__repository + \"-\" + .tag_name"
        title      = ".name // .tag_name"
        blueprint  = "\"${port_blueprint.release.identifier}\""
        properties = {
          version      = ".tag_name | ltrimstr(\"v\")"
          published_at = ".published_at"
          changelog    = ".body"
          url          = ".html_url"
        }
        relations = {
          service = local.service_of_repo
          # builds lo añade publish.yml al re-etiquetar (F3.4); la fusión de entidades lo conserva
        }
      } } }
    },
    {
      kind     = "workflow"
      selector = { query = "true" }
      port = { entity = { mappings = {
        identifier = ".__repository + \"-\" + (.id | tostring)"
        title      = ".name"
        blueprint  = "\"githubWorkflow\""
        properties = {
          path      = ".path"
          status    = ".state"
          link      = ".html_url"
          createdAt = ".created_at"
          updatedAt = ".updated_at"
        }
        relations = {
          repository = ".__repository"
        }
      } } }
    },
    {
      kind = "workflow-run"
      selector = {
        query = "true"
        since = 30 # días: alimenta las scorecards de fiabilidad de la plantilla
      }
      port = { entity = { mappings = {
        identifier = ".__repository + \"-\" + (.id | tostring)"
        title      = ".display_title // .name"
        blueprint  = "\"githubWorkflowRun\""
        properties = {
          name            = ".name"
          status          = ".status"
          conclusion      = ".conclusion"
          headBranch      = ".head_branch"
          runNumber       = ".run_number"
          runAttempt      = ".run_attempt"
          runStartedAt    = ".run_started_at"
          createdAt       = ".created_at"
          updatedAt       = ".updated_at"
          link            = ".html_url"
          triggeringActor = ".triggering_actor.login"
        }
        relations = {
          repository   = ".__repository"
          workflow     = ".__repository + \"-\" + (.workflow_id | tostring)"
          pullRequests = "[.__repository as $r | .pull_requests[]? | $r + \"-\" + (.number | tostring)]"
          service      = local.service_of_repo
        }
      } } }
    },
  ]
}

resource "port_integration" "github_ocean" {
  installation_id       = "github-ocean"
  installation_app_type = "github-ocean"
  installation_type     = "SaasOAuth2"

  config = jsonencode({
    deleteDependentEntities      = true
    createMissingRelatedEntities = true
    enableMergeEntity            = true # pipelines e integración escriben en las mismas entidades
    entityDeletionThreshold      = 0.9
    resources                    = local.github_ocean_resources
  })

  lifecycle {
    # La instalación (GitHub App, live events, versión) la gestiona Port: no va al repo público
    ignore_changes = [spec, version, title]
  }
}
