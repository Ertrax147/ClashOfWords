# Clash of Words

App móvil educativa para tablets Android que digitaliza un juego de cartas físico para estudiantes de 5° y 6° básico (vocabulario en inglés, comprensión lectora, expresión oral y convivencia escolar). Proyecto del ramo Proyecto de Investigación e Innovación, Universidad de La Frontera. Contraparte: Orlando Muñoz, profesor de inglés y creador del juego.

## Fuentes de verdad

- Requisitos: `docs/SRS.md` (IEEE 830: RF-01 a RF-18, RNF-01 a RNF-10, CU-01 a CU-11). Es largo: leer solo la sección o el requisito que se esté implementando.
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
- Los Items Epic y Legendary no tienen Class y pueden equiparse a cualquier Creature. Un Item con Class solo se equipa a una Creature que comparta al menos una Class con él.
- Cada Creature tiene una sola Class; los Items pueden tener varias. En un Clash con igual Rarity y la misma Class hay Tie, sin importar el Power (Paso 3 del manual).
- Si el manual se contradice sobre a dónde van las Creatures tras un Clash, manda el Paso 5: ganadora al Discard Stack de su dueño y perdedora al Trophy Stack del rival.

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
