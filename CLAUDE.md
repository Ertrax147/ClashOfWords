# Clash of Words

App móvil educativa para tablets Android que digitaliza un juego de cartas físico para estudiantes de 5° y 6° básico (vocabulario en inglés, comprensión lectora, expresión oral y convivencia escolar). Proyecto del ramo Proyecto de Investigación e Innovación, Universidad de La Frontera. Contraparte: Orlando Muñoz, profesor de inglés y creador del juego.

## Fuentes de verdad

- `docs/SRS.md` es la versión 1.4 (15-10-2026) del SRS, convertida del documento oficial. Reemplaza a la copia anterior (v1.1), que estaba desactualizada. Las decisiones de arquitectura y datos vigentes son las de la sección "Arquitectura y datos".
- Requisitos: `docs/SRS.md` (IEEE 830: RF-01 a RF-18, RNF-01 a RNF-10, CU-01 a CU-15). Es largo: leer solo la sección o el requisito que se esté implementando.
- Reglas del juego: el manual de Orlando no está en el repositorio (es su material). Las reglas relevantes están en docs/SRS.md (RF-04, RF-10) y en las decisiones de más abajo. Si hay dudas, preguntar al usuario.
- RF-04 y RF-10 del SRS están desactualizados en lo que cubre la sección "Duration, Rarity y Class de Items": mientras no se corrija el SRS, mandan esas decisiones.
- Si el código y el SRS se contradicen, avisar y no decidir solo.

## Stack y restricciones

- Flutter y Dart. Objetivo: tablets Android (Android 8.0 o superior, pantallas de 7 a 11 pulgadas, horizontal).
- La lógica del juego va separada de la interfaz y del almacenamiento (RNF-09). El motor debe poder probarse sin Flutter.
- Funciona sin internet: partidas contra el sistema y 1 vs 1 local. El canje de códigos y la actualización del catálogo sí requieren conexión (RF-08).
- La interfaz va íntegramente en inglés. Lo único en español es la traducción de las habilidades (ventana emergente).
- No guardar datos personales de los estudiantes: solo un nombre de usuario asignado por el profesor (RNF-05).

## Decisiones ya tomadas (no reabrir sin avisar)

- Contra el sistema hay dos niveles: Fácil (mazo aleatorio) y Normal (Items y Effects acordes a las Class de sus Creatures). No otorga recompensa.
- Mazo inicial: 22 cartas (21 más un Initial Effect), misma cantidad de cada tipo para todos, Rarity al azar, Items y Effects acordes a las Class de las Creatures. Saldo inicial de 100 coins.
- Mazo del estudiante: 20 a 25 cartas más un único Initial Effect, máximo 3 copias de una misma carta.
- Initial Effect: si es pasivo, actúa toda la partida; si es activo, se usa una vez por partida.
- Los Items acompañan a su Creature al Discard Stack o al Trophy Stack y cuentan como trofeo.
- Empate en trofeos: sin intercambio. Si el ganador no tiene cartas propias en el Trophy Stack rival, solo recibe.
- Desconexión en 1 vs 1: pausa de 60 segundos; si no se recupera, se cancela sin intercambio ni registro.
- Sobres de 3 cartas a 50 coins. Probabilidades por defecto: Common 50 %, Uncommon 25 %, Rare 15 %, Epic 8 %, Legendary 2 %. Las coins solo se obtienen con códigos del profesor.
- Fuera de alcance por ahora: modos adaptados para distintas habilidades, juego en línea por internet, validación de pronunciación con micrófono.

### Duration, Rarity y Class de Items

Definidas a partir de las cartas y del manual, porque el SRS no las recoge. Pendientes de validar con Orlando.

- Una Creature sin Duration dura 1 Clash. Con Duration N, la ganadora sigue en juego y enfrenta a la siguiente Creature del rival hasta completar N Clashes; luego va al Discard Stack de su dueño. Duration ∞: sigue hasta perder o hasta que termine la partida.
- La Duration se descuenta en cada Clash en que participa la Creature, gane o empate (un Tie cuenta como Clash).
- Si pierde, va al Trophy Stack del rival aunque le quede Duration. Su Item sigue equipado mientras ella esté en juego y la acompaña a la pila que corresponda.
- La Duration que aparece en un Item es la que otorga a su Creature, no la duración del Item.
- Items, Effects e Initial Effects pueden cambiar la Rarity o la Duration de una Creature. Se conserva siempre la mayor entre la que tenía y la que recibe: nunca empeoran a la Creature. Los modificadores de un Item valen mientras esté equipado; los de un Effect, mientras dure.
- Un Item sin Class puede equiparse a cualquier Creature (en las cartas hay Items Rare, Epic y Legendary sin Class). Un Item con Class solo se equipa a una Creature que comparta al menos una Class con él.
- Cada Creature tiene una sola Class; los Items pueden tener varias. En un Clash con igual Rarity y la misma Class hay Tie, sin importar el Power (Paso 3 del manual).
- En un Tie, las dos Creatures se apartan con sus Items aunque les quede Duration, y se revelan Creatures nuevas (CU-01, flujo de desempate T1 a T5). Al resolverse, las apartadas del ganador van a su Discard Stack y las del perdedor al Trophy Stack del ganador.
- La ganadora del Clash que resuelve un Tie respeta su propia Duration: si le quedan Clashes, sigue en la mesa. CU-01 (T4) dice que las ganadoras van al Discard Stack, pero se escribió antes de definir la Duration.

### Effects y habilidades

- Las habilidades de Creatures, Items y Effects se describen como datos (modificar Power, Rarity o Class; sacar Creatures rivales; prohibir jugadas). Los Initial Effects se programan uno por uno.
- La regla de "la mayor" solo aplica a lo que se le da a las Creatures propias. Lo que apunta al rival ("Enemy creatures get -3", "Enemy Wild creatures get Common") sí puede bajarle el Power y la Rarity.
- "Your creatures get <Class>" agrega la Class: la Creature conserva la suya. Con las Class agregadas puede equipar Items de esa Class, y en el Clash hay Tie si las dos Creatures comparten al menos una Class.
- "Move the enemy <Class> creature to the Discard stack": la Creature rival y su Item van al Discard Stack de su dueño (no son trofeo) y el rival revela otra para el mismo Clash. Mientras dure el Effect, se aplica también a las Creatures que el rival revele.
- Se pueden jugar varios Effects en un mismo Clash, antes de resolverlo. Su Duration cuenta desde el Clash en que se juegan e incluye los Ties.
- "Your enemy cannot play Effects/Items" impide jugar cartas nuevas, pero no cancela las que ya están en juego.
- Si el manual se contradice sobre a dónde van las Creatures tras un Clash, manda el Paso 5: ganadora al Discard Stack de su dueño y perdedora al Trophy Stack del rival.

### Initial Effects pasivos

Interpretaciones del equipo, porque el manual no da detalles. Pendientes de validar con Orlando.

- Diversity: la primera Creature de cada Class que entra en juego tiene +2 mientras siga en la mesa; las siguientes de esa Class, no.
- Tolerance: cuentan todas las derrotas, incluidas las de resolver un Tie. El Item acompaña a su Creature al Discard Stack.
- Responsibility (pasiva): sin límite de Items por Creature. Cada Item suma su Power; de Rarity y Duration se queda la mayor.
- Respect: si hay Tie por Class y su Creature tiene más Power, gana. Con igual Power sigue siendo Tie.
- Justice: +1 por cada Clash perdido desde la última victoria. Los Ties no suman ni reinician.
- Friendship: +3 solo en el Clash que sigue a un Tie. No se acumula con varios Ties seguidos.
- Excellence: +1 solo en el Clash que sigue a una victoria, aunque pelee la misma Creature.
- Empathy: copia el Initial Effect del rival, pasivo o activo (el activo se puede usar una vez). Si ambos tienen Empathy, no copia nada.

### Initial Effects activos

Interpretaciones del equipo, tomadas de `docs/initial-effects.md`, porque el manual no da detalles. **Pendientes de validar con Orlando.** Las que ya vienen del texto de la carta no se repiten aquí.

- Todas se usan una vez por partida, en la fase de jugar (antes de resolver el Clash). La excepción es Commitment, que se usa después de perder un Clash. Una jugada no permitida se rechaza con un motivo.
- Recycle: se elige una Creature del propio Discard Stack. Vuelve sola al Deck; si tenía un Item, este se queda en el Discard Stack. Sin Creatures en el Discard Stack no se puede usar.
- Responsibility (activa): igual que Recycle, pero con un Item. Vuelve solo el Item, aunque su Creature siga en el Discard Stack.
- Loyalty: la Creature propia que está en el Trophy Stack del rival vuelve al Discard Stack propio, con sus Items, y el rival pierde ese trofeo. Un Item que el rival le quitó con Kindness no vuelve.
- Leadership: "Duración: 3 Clashes" cuenta el Clash en que se usa. Si la Creature ya tenía más Duration, la conserva. Si pierde antes de completarla, va al Trophy Stack del rival.
- Kindness: la carta superior del Deck rival pasa al Trophy Stack propio, sea Creature, Item o Effect. Si era la última, la partida termina al revelar el siguiente Clash.
- Honesty: se ven las 3 cartas superiores de cada Deck y se reordenan ambas. Si un Deck tiene menos de 3, se reordenan las que tiene. El rival no recibe información (sin definir).
- Generosity: se toma un Item o Effect de la Hand del rival (no uno que ya esté en juego). Sigue siendo del rival: al agotarse vuelve a su Discard Stack y nunca cuenta como trofeo.
- Creativity: se elige una Creature del Deck y reemplaza a la de la mesa; la reemplazada va con su Item al Discard Stack propio, sin ser trofeo. La nueva pelea el Clash actual. Luego se baraja el Deck.
- Commitment: al perder un Clash, el perdedor decide si la usa o la rechaza; hasta entonces el Clash no se aplica. Si la usa, gana ese Clash y mueve una Creature de su Trophy Stack, con sus Items, al Discard Stack del rival (si no tiene ninguna, solo gana). Si la rechaza, el Clash se aplica como se resolvió y puede usarla en otro. Un Tie no abre la decisión. Ningún Effect del rival puede impedirla.
- Empathy: copia también la habilidad activa del rival, y se puede usar una vez. Si ambos tienen Empathy, ninguno copia nada.

### Arquitectura y datos

Lo que el equipo decidió, según el contrato de la API v1.0 y el SRS actualizado. Cada punto dice si ya está en el repo o es **decidido, aún no implementado**.

**Ya implementado**

- El proyecto es un workspace de Dart: la app (`lib/`) y el motor (`packages/game_engine`). El motor es Dart puro, sin Flutter, y un test falla si se le agrega Flutter como dependencia (RNF-09). Los 16 Initial Effects tienen lógica fija en el motor.
- La app sigue clean architecture por funcionalidad: cada carpeta de `lib/features/` tiene `domain/`, `data/` y `presentation/`. El estado se maneja con Riverpod.
- Catálogo: 422 cartas en `assets/catalog/cards.json`, con imágenes en `assets/cards/<id>.jpg`, leídas a través de la interfaz `CatalogRepository`.
- Cada copia de una carta en la partida es una `MatchCard` con su dueño: el Discard Stack solo guarda cartas propias y el Trophy Stack solo cartas del rival.

**Decidido, aún no implementado** (el repo todavía no usa Supabase, drift ni Nearby Connections)

- Backend: Supabase (PostgreSQL con 14 tablas, Auth, Storage y Edge Functions). Las Edge Functions son código del proyecto, y Supabase va dentro del sistema. El contrato de la API v1.0 tiene 28 endpoints en 6 grupos; las reglas del juego no usan API.
- Estudiante y profesor usan la misma app según su rol; el panel del profesor va dentro de ella.
- Base local: SQLite con drift, offline-first, con cola de sincronización (outbox). Es una copia parcial del catálogo para jugar sin conexión, con tablas propias de sesión, cola de sincronización, historial y metadatos. La nube es la fuente de verdad: si un dato no coincide, manda la nube.
- Login: el estudiante entra solo con nombre de usuario; el profesor, con credenciales y PIN. El login pasa por Edge Functions, no directo por Auth.
- El motor corre en la tablet. En 1 vs 1 lo corre la tablet que envía el desafío.
- Conectividad 1 vs 1: Google Nearby Connections, sin internet.
- El servidor decide monedas, sobres y canjes. La compra de sobres usa `Idempotency-Key`. El intercambio de cartas usa un `partida_id` único.
- Catálogo: la app trae una copia base y sincroniza las diferencias con `actualizada_en`.
- IDs: las cartas usan un slug de texto estable; el resto, UUID generado en la tablet.
- Los Initial Effects no se crean desde el panel: solo se editan nombre, imagen, audio y traducción.
- Sin internet se puede: jugar contra el sistema y 1 vs 1 local, armar mazos, ver la colección, escuchar audios guardados y ver el historial. Requieren conexión: el primer login en una tablet nueva, comprar sobres, canjear códigos, actualizar el catálogo y el panel del profesor.

## Flujo de Git

- `main`: estable y entregable. No se trabaja directo en ella; solo recibe merges desde `dev`.
- `dev`: rama de integración. Todo se junta aquí.
- `feature/<nombre-corto>`: una rama por funcionalidad, creada desde `dev` y unida a `dev` mediante Pull Request. Lo mismo para `fix/<nombre>` y `docs/<nombre>`.
- Commits pequeños, uno por cada cambio lógico, con prefijo: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
- Mensajes de commit y documentación en español; código y nombres de variables en inglés.
- Antes de abrir un Pull Request: los tests pasan y `flutter analyze` no tiene errores.
- No hacer force push a `main` ni a `dev`.
- No hacer commit ni push sin que el usuario lo pida. Mostrar primero los cambios y proponer el mensaje del commit.

## Cómo trabajar

- Pedir primero un plan breve cuando la tarea toque varios archivos.
- Cada funcionalidad nueva lleva sus tests, empezando por el motor del juego (resolución de Clash, Items, Effects, pilas).
- Citar el RF o el CU que se está implementando en el mensaje del commit o en el Pull Request.
