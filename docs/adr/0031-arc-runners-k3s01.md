# ADR 0031 · ARC en k3s01: `gha-runner-scale-set`, GitHub App dedicada de un solo repo

- **Estado:** Aceptada · 2026-11-13 · desarrolla [01-arquitectura](../01-arquitectura.md) §5 y el [roadmap](../02-roadmap.md) F5

## Contexto

F5 necesita *runners* self-hosted efímeros en k3s01 para los *jobs* de CI que necesitan la LAN
(hablar con HarnessRouter): el proyecto real es `actions/actions-runner-controller`, con dos
*charts* Helm en el registro OCI de GitHub, versión verificada contra el registro real
(`helm show chart`, no asumida): `gha-runner-scale-set-controller` y `gha-runner-scale-set`, ambas
**0.15.1**. El controlador instala sus CRD desde la carpeta especial `crds/` del *chart*; confirmado
que Argo CD las aplica solas (`helm template --include-crds` es su comportamiento por defecto,
salvo `source.helm.skipCrds: true`, que no se usa aquí).

Autenticación: la *chart* del *runner scale set* admite PAT, GitHub App, o un secreto de Kubernetes
ya creado con esas mismas claves. Reutilizar `elpalmeral-platform-bot` (la App ya instalada en
`meridian-orders` desde F4.4) ampliaría sus permisos — la ADR 0014 fija «permisos mínimos y por
repositorio»; ARC necesita permisos muy distintos (`Administration: Read & write` a nivel de repo,
para registrar y retirar *runners*) que no tienen nada que ver con lo que ya hace esa App
(releases, PR de *upgrade*). Permisos exactos verificados contra la documentación real del
proyecto: `Actions: Read`, `Administration: Read & write`, `Metadata: Read` (ninguno a nivel de
organización, porque la instalación es de un solo repositorio).

## Decisión

1. **GitHub App dedicada `elpalmeral-arc-runners`**, instalada **solo en `meridian-orders`**, con
   esos tres permisos exactos y nada más. Clave privada y IDs en 1Password
   (`agentic-lab/arc-runners`: `app_id`, `installation_id`, `private_key`), llevados al clúster por
   `ExternalSecret` como un secreto "pre-definido" de la *chart* (mismas claves que la variante de
   GitHub App: `github_app_id`, `github_app_installation_id`, `github_app_private_key`).
2. **Dos `Application` de Argo CD**, *charts* Helm del registro OCI directo (sin `oci://` en
   `repoURL`, confirmado contra la documentación de Argo CD): `arc-controller` (namespace
   `arc-system`, ola 7) y `arc-runner-scale-set` (namespace `arc-runners`, ola 8, con una segunda
   fuente en el propio repo solo para el `ExternalSecret`).
3. **Un *runner scale set* por ahora**, `arc-aidlc`, apuntando solo a `meridian-orders`
   (`githubConfigUrl`). Si en el futuro hace falta otro repo, se amplía la instalación de la App o
   se crea una segunda App — igual que ya se decidió para `elpalmeral-platform-bot` (ADR 0029).
4. **`minRunners: 0`, `maxRunners: 2`.** *Runners* efímeros (un *pod* por *job*, se borran al
   terminar): en reposo no consumen nada del clúster, coherente con el presupuesto de
   01-arquitectura §6 («HarnessRouter + runners ARC (pico)»).
5. **Sin modo contenedor especial** (`containerMode` vacío, imagen `actions-runner` tal cual): los
   *jobs* de este *runner* llaman a la API de HarnessRouter por HTTP (`curl`/`jq`), no construyen
   imágenes ni necesitan Docker-in-Docker. Menos superficie, menos recursos.
6. **Alcance de este paso: desplegar ARC y comprobar que registra el *runner* y ejecuta un *job*
   trivial.** Los *workflows* reales `aidlc-propose`/`aidlc-implement` que llaman a
   `meridian/<rol>@X.Y.Z` en HarnessRouter dependen de F4.7 (publicar los roles, conectar
   proveedores), que sigue pendiente de confirmar por el gasto de OpenRouter y el uso de Bonsai: no
   se escriben todavía esos *workflows* contra una HarnessRouter sin roles publicados.

## Consecuencias

- ✅ Ninguna identidad automatizada existente amplía su alcance; cada una hace una sola cosa
  (ADR 0014 §«permisos mínimos y por repositorio», ya aplicado también en ADR 0029).
- ✅ El coste en reposo es ~0: *runners* efímeros, sin *pods* permanentes más allá del controlador
  (pequeño) y el *listener* del *scale set* (uno, ligero).
- ⚠️ F5 queda a medio camino hasta que F4.7 desbloquee el motor A real: ARC puede ejecutar *jobs*,
  pero los que de verdad hablan con HarnessRouter todavía no existen.
- ⚠️ Añade dos *pods* permanentes más al clúster (controlador + *listener*), aunque pequeños: suma
  presión sobre un nodo ya al ~116 % de límites (aceptado explícitamente para F4.6; se repite el
  mismo criterio aquí, dado el tamaño modesto).
