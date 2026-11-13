# FAQ cliente · preguntas habituales y respuestas con hechos reales

> Cada respuesta cita algo que se puede enseñar, no una afirmación de folleto. Si la pregunta no
> está aquí y no se sabe la respuesta con un hecho real detrás: "lo compruebo y te lo confirmo" es
> mejor que improvisar un número.

## Seguridad

**"¿Los agentes pueden escribir código sin que nadie lo revise?"**
No. Dos puertas humanas obligatorias: el PR de la *spec* (antes de que exista código) y el PR del
código (antes de fusionar a `main`). Los agentes proponen; las personas deciden
([ADR 0025](../adr/0025-dos-motores-un-harness.md)).

**"¿Qué pasa si el agente mete un fallo de seguridad?"**
Pasó de verdad, no es hipotético: en la primera ejecución real de esta *feature*, `security-gate`
encontró que un dato personal se filtraba al log de acceso. Bloqueó el PR, se corrigió de raíz
(no un parche) y se volvió a validar antes de fusionar. Es el ejemplo del acto 2.

**"¿Dónde van los datos de clientes? ¿A qué modelo?"**
Hay una clasificación de datos (C1-C4) en el corpus corporativo, y los validadores la comprueban
en cada PR. Los datos C3 (personales) solo pueden llegar al modelo local (Bonsai), nunca a un
proveedor externo — lo aplica `security-gate`, no una política en un documento sin dientes.

**"¿Las imágenes están firmadas?"**
Sí, con *cosign* y la identidad OIDC del propio *workflow* de CI — nunca una identidad personal
(evita publicar un correo personal en el registro público de Sigstore). Se verifica en cada
despliegue, no solo al construir.

## Coste

**"¿Cuánto cuesta un agente?"**
Por ejecución, no por asiento. El motor abierto (OpenRouter/Bonsai) cuesta tokens reales — la
última prueba de humo gastó 0,0068 $ por una respuesta completa con *grounding*. El motor Claude
Code va por la suscripción de la empresa, coste fijo conocido.

**"¿Y si se descontrola el gasto?"**
La clave de OpenRouter tiene un tope duro de 10 $ sin recarga automática — no hay sorpresa posible
salvo que alguien suba el límite a propósito. El remanente es visible en el catálogo de servicios,
no en una factura a fin de mes.

## *Lock-in*

**"¿Esto nos ata a un proveedor de modelos?"**
No: el mismo harness (mandato, herramientas, validadores) corre por dos motores — uno abierto
(cualquier proveedor compatible con OpenAI, incluido un modelo propio en la LAN) y uno con Claude
Code. Cambiar de proveedor es una variable de conexión, no un reescritura de los agentes.

**"¿Y si queremos un modelo propio, sin salir a Internet?"**
Ya está probado: Bonsai es un modelo local (27B), conectado al mismo harness, mismo mandato, coste
cero. Más lento que la nube (~19 s frente a unos pocos segundos en la última prueba), pero
funcional para tareas de un solo turno; un bucle agéntico largo con herramientas todavía no se ha
medido.

## Gobierno

**"¿Cómo sabemos qué versión del harness usa cada servicio?"**
Cada servicio tiene su versión del harness fijada, verificada (sin *drift*, firma comprobada,
versión mínima cumplida) visible en su ficha — scorecard `harness_governance`, no una hoja aparte.

**"¿Qué pasa si alguien edita el harness a mano, sin pasar por el proceso?"**
Una política determinista (OPA) lo bloquea en el PR: cambiar ficheros del harness sin la etiqueta
y el autor correctos frena el *merge*, para personas y para bots por igual.

**"¿Esto funciona con nuestro stack, o es solo para este caso de ejemplo?"**
El laboratorio corre sobre Kubernetes, GitOps y GitHub Actions — pieza por pieza, cada decisión
(ADR) explica el motivo y la alternativa descartada. El servicio de ejemplo es intercambiable; la
plataforma (harness, puertas, gobierno) no está atada a él.

## Preguntas incómodas (mejor tenerlas preparadas)

**"¿Todo esto es real, o es una maqueta para la demo?"**
Real: cada PR, cada firma, cada hallazgo de un *gate* tiene un número de PR auditable en GitHub.
Si algo falla en directo (puede pasar: hay una CVE real bloqueando un despliegue mientras se
escribe esto), es un hallazgo real de una puerta real, no un fallo de guion.

**"¿Cuánto tardaría en funcionar esto con nuestros repos reales?"**
Depende del punto de partida (CI ya existente, catálogo de servicios, política de datos ya
escrita o no). No hay un número genérico honesto — es la primera pregunta de un diagnóstico, no
de esta demo.
