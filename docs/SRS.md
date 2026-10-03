> Copia en Markdown del SRS (versión 1.1, 02-10-2026) para usar como referencia dentro del repositorio. El documento oficial de la entrega es el de Google Docs; si se actualiza, hay que regenerar este archivo. El diagrama de casos de uso (Figura 1) no se incluye en esta copia.

Clash of Words — Especificación de Requisitos de Software 

**Universidad de La Frontera**

Facultad de Ingeniería y Ciencias — Ingeniería en Informática

**ESPECIFICACIÓN DE REQUISITOS DE SOFTWARE**

**Clash of Words**

Entrega — IEEE 830

| **Campo** | **Información** |
| --- | --- |
| Proyecto | Clash of Words |
| Asignatura | Proyecto de Investigación e Innovación |
| Autores | Daniel Sepúlveda Cristopher Gallegos Carlos Cienfuegos Nahuel Catrileo |
| Versión | 1.1 |
| Fecha de actualización | 02-10-2026 |
| Documento | Especificación de Requisitos de Software (SRS) |

# Ficha del documento

| **Fecha** | **Revisión** | **Autor** | **Descripción** |
| --- | --- | --- | --- |
| 18-09-2026 | 1.0 | Daniel Sepúlveda | Creación y Completado de documento |
| 02-10-2026 | 1.1 | Cristopher Gallegos | Edición de Documento |

Documento validado por las partes en fecha: ______________________________

| **Responsable académico / estudiante** | **Contraparte educativa** |
| --- | --- |
| Daniel Sepúlveda Cristopher Gallegos Carlos Cienfuegos Nahuel Catrileo Firma: ____________________ | Orlando Muñoz Firma: ____________________ |

# Índice

# 1. Introducción

En el contexto de la educación básica en Chile, la enseñanza del idioma inglés enfrenta desafíos significativos, tales como la asignación limitada de horas pedagógicas y la reducida exposición de los estudiantes al idioma fuera del entorno escolar. Esta situación puede traducirse en dificultades para adquirir vocabulario y en inseguridad al momento de utilizar el idioma de forma oral.

Paralelamente, en los establecimientos educacionales se observan dinámicas de juego durante los tiempos de esparcimiento que pueden generar conflictos de convivencia. Para abordar estas problemáticas en la Escuela Particular 239 Los Volcanes de Llanquihue, se diseñó el juego de cartas físico «Clash of Words» [2]. Sin embargo, la reproducción de material físico a gran escala representa un costo de producción elevado y dificulta la actualización constante de contenidos. Diversos estudios indican que los juegos de mesa favorecen la expresión oral en inglés [3], [5] y la convivencia escolar [4]. 

El presente documento formaliza la especificación de requisitos del software para digitalizar dicho juego mediante una aplicación móvil, manteniendo sus mecánicas principales e incorporando herramientas multimedia, gestión de contenidos y seguimiento básico del progreso.

## 1.1. Propósito

El propósito principal del proyecto es desarrollar una aplicación móvil que digitalice la experiencia del juego de cartas educativo «Clash of Words». La solución busca superar las limitaciones asociadas a la impresión física mediante una plataforma interactiva y escalable.

La digitalización también busca apoyar la adquisición de vocabulario en inglés, la comprensión lectora y la expresión oral mediante recursos de pronunciación. Asimismo, el sistema contempla un panel de administración que permitirá al docente actualizar contenidos y consultar información agregada del progreso de los estudiantes.

## 1.2. Alcance

El alcance contempla el diseño y desarrollo de una aplicación móvil para tablets Android, destinada a estudiantes de 5° y 6° año de enseñanza básica, junto con un panel de administración para el docente. La versión incluye:

- Acceso diferenciado: ingreso de los estudiantes con un nombre de usuario creado por el profesor e ingreso del profesor con credenciales y PIN de seguridad.

- Motor de partida (Gameplay): automatización de las reglas del juego físico, incluido el uso de Items, Effects e Initial Effects, en dos modalidades: partida contra un rival controlado por el sistema, con dos niveles de dificultad, y partida 1 vs 1 entre dos tablets cercanas, sin requerir acceso a internet.

- Partida 1 vs 1 local: conexión entre dispositivos cercanos, sincronización del estado de la partida, manejo de desconexiones e intercambio de cartas al finalizar.

- Gestor de mazos (Deck Builder): visualización de la colección y conformación de mazos válidos, además de un mazo inicial para cada estudiante.

- Apoyo al aprendizaje del inglés: vista ampliada de cada carta, audio de pronunciación y traducción al español de las habilidades.

- Economía de juego: coins, compra y apertura de sobres, y canje de códigos entregados por el profesor.

- Panel de administración (CMS): gestión del catálogo de cartas y sus atributos, generación de códigos de recompensa y consulta de estadísticas.

- Seguimiento de progreso: registro de partidas, resultados y cartas obtenidas.

Quedan fuera de esta versión: los modos de juego adaptados a estudiantes con distintas habilidades, el juego en línea a través de internet, el intercambio de más de una carta, la validación de la pronunciación mediante micrófono y las recompensas por ganar contra el sistema. Estos puntos se consideran en la sección 2.6.

Límites principales: la primera versión estará orientada a Android; deberá privilegiar tecnologías de bajo costo, bajo consumo de datos y funcionamiento parcial sin conexión. También deberá considerar protección de datos de menores, propiedad intelectual y accesibilidad.

## 1.3. Personal involucrado

| **Nombre** | **Rol** | **Categoría** | **Responsabilidades** |
| --- | --- | --- | --- |
| Daniel Sepúlveda | Desarrollador y analista | Ingeniería / desarrollo de software | Análisis de requisitos, diseño e implementación de funcionalidades, pruebas y validación del sistema, documentación técnica y coordinación con la contraparte. |
| Cristopher Gallegos | Desarrollador y analista | Ingeniería / desarrollo de software | Análisis de requisitos, diseño e implementación de funcionalidades, pruebas y validación del sistema, documentación técnica y coordinación con la contraparte. |
| Carlos Cienfuegos | Desarrollador y analista | Ingeniería / desarrollo de software | Análisis de requisitos, diseño e implementación de funcionalidades, pruebas y validación del sistema, documentación técnica y coordinación con la contraparte. |
| Nahuel Catrileo | Desarrollador y analista | Ingeniería / desarrollo de software | Análisis de requisitos, diseño e implementación de funcionalidades, pruebas y validación del sistema, documentación técnica y coordinación con la contraparte. |
| Orlando Muñoz | Contraparte educativa y creador del juego físico | Profesor de Inglés | Definir y validar reglas de negocio, mecánicas del juego y contenido del vocabulario en inglés. |

Los cuatro integrantes del equipo de desarrollo comparten por igual las responsabilidades del proyecto. La contraparte educativa valida las reglas del juego y el contenido.

## 1.4. Definiciones, acrónimos y abreviaturas

Los términos del juego se definen según el manual del juego [6]. 

| **Término / acrónimo** | **Definición** |
| --- | --- |
| SRS | Software Requirements Specification. Especificación de requisitos de software. |
| RF / RNF / CU | Requisito funcional / Requisito no funcional / Caso de uso. |
| CMS | Content Management System. Sistema de gestión de contenidos para administrar el vocabulario y las cartas. |
| WCAG 2.1 | Web Content Accessibility Guidelines. Directrices de accesibilidad aplicables a contenidos digitales. |
| Deck | Mazo o baraja de cartas del jugador. |
| Hand (mano) | Cartas Item o Effect que el jugador ha revelado y guarda para usar durante un Clash. |
| Creature | Carta que se enfrenta en un Clash; tiene Rarity, Class y Power. |
| Item | Carta que mejora a una Creature. Una Creature puede llevar un solo Item y debe compartir al menos una Class con él. |
| Effect | Carta que modifica las reglas del juego durante una cantidad de Clashes indicada en la carta. |
| Initial Effect | Carta única por jugador que permanece en juego durante toda la partida. Su habilidad puede ser pasiva (siempre activa) o activa (la activa el jugador). Tiene Rarity Value y no tiene Power. |
| Clash | Enfrentamiento entre dos Creatures reveladas. |
| Tie | Empate de un Clash; se resuelve con un nuevo Clash. |
| Rarity | Rareza de una carta: Common, Uncommon, Rare, Epic y Legendary. Los Initial Effect tienen una categoría exclusiva, Value. |
| Class | Categoría temática de una carta; determina qué Items pueden usarse con cada Creature. |
| Power | Valor numérico de una Creature o modificador de un Item. |
| Trophy Stack | Pila de cartas del rival que el jugador venció. |
| Discard Stack | Pila de cartas ya usadas o que ganaron un Clash. |
| Coins | Moneda del juego, que se usa para comprar sobres. |
| Sobre | Paquete de 3 cartas seleccionadas al azar del catálogo activo. |

## 1.5. Referencias

[1] IEEE, «IEEE Std 830-1998: IEEE Recommended Practice for Software Requirements Specifications», IEEE, 1998.

[2] O. Muñoz, «Proyecto Educativo: Clash of Words», 2026.

[3] Y. M. Fung y L. M. Yeo, «Effects of board game on speaking ability of low-proficiency ESL learners», International Journal of Applied Linguistics & English Literature, vol. 5, n.º 3, pp. 261–269, 2016.

[4] C. Muñoz y D. Vargas, «El juego de mesa como estrategia para la mejora de la convivencia escolar en recreos educativos», Revista Latinoamericana de Estudios Educativos, vol. 11, n.º 2, pp. 89–104, 2015.

[5] Y. D. Prastyo, S. Silviyani y Y. Y. Dharmawan, «The effect of board games on students' communicative competence», Journal of Linguistics and Language Education, vol. 5, n.º 2, pp. 149–155, 2020, doi: 10.29407/jetar.v5i2.14633.

[6] O. Muñoz, «Clash of Words: Player's Manual», 2026.

## 1.6. Resumen

Este documento especifica los requisitos de Clash of Words, una aplicación móvil educativa para tablets Android que digitaliza un juego de cartas físico para estudiantes de 5° y 6° básico, con un panel de administración para el docente. La sección 1 presenta el propósito, el alcance, el personal involucrado, las definiciones y las referencias. La sección 2 describe la perspectiva y la funcionalidad del producto, las características de los usuarios, las restricciones, las suposiciones y la evolución prevista. La sección 3 detalla las interfaces del sistema, los 18 requisitos funcionales y los 10 requisitos no funcionales, organizados por categoría de calidad. El apéndice incluye el diagrama y la especificación de los casos de uso que describen el comportamiento esperado del sistema. 

# 2. Descripción general

## 2.1. Perspectiva del producto

Clash of Words será un producto de software independiente, desarrollado inicialmente como aplicación móvil Android y complementado por un panel de administración docente. El sistema digitaliza un juego de cartas físico previamente definido, por lo que debe respetar sus mecánicas centrales, su finalidad pedagógica y su uso como recurso de convivencia escolar.

El sistema no forma parte obligatoria de una plataforma institucional mayor. Podrá utilizarse como apoyo en clases de inglés, talleres, recreos dirigidos o actividades de convivencia. Debido a posibles limitaciones de conectividad, se priorizarán almacenamiento local, sincronización controlada y bajo consumo de datos.

- Aplicación móvil del estudiante: visualizar cartas, escuchar audios, construir mazos, iniciar partidas y consultar progreso básico.

- Panel de administración docente: administrar el catálogo didáctico, editar atributos y gestionar recompensas o códigos de canje.

- Motor de juego: procesar las reglas del juego físico, Clashes, empates, uso de Items y Effects, pilas de cartas y condiciones de término, tanto en partidas contra el sistema como en partidas 1 vs 1 local. 

- Repositorio de contenido: almacenar cartas, vocabulario, imágenes, audios y metadatos pedagógicos.

- Almacenamiento local y sincronización: conservar datos mínimos en el dispositivo y sincronizar cambios cuando exista conexión.

- Módulo de seguimiento: registrar información básica de uso y resultados evitando datos personales sensibles.

## 2.2. Funcionalidad del producto

| **Prioridad** | **Funcionalidad** | **Descripción** |
| --- | --- | --- |
| Alta | Acceso diferenciado por rol | Permitir el uso por estudiantes y profesores, evitando acceso estudiantil a funciones administrativas. |
| Alta | Gestión del catálogo de cartas | Crear, editar, consultar y desactivar cartas, incluyendo atributos lingüísticos y lúdicos. |
| Alta | Colección y construcción de mazos | Revisar cartas disponibles y construir un mazo válido. |
| Alta | Ejecución automatizada de partidas | Resolver automáticamente los Clashes aplicando las reglas de rareza, clase, poder y desempate. |
| Alta | Apoyo al aprendizaje del inglés | Mostrar cada carta en vista ampliada con su vocabulario y opción de escuchar su pronunciación. |
| Media | Gestión de recursos multimedia | Reproducir a solicitud el audio de pronunciación de cada carta, también sin conexión. |
| Media | Distribución de recompensas | Generar códigos de canje de coins o sobres para estudiantes o cursos completos. |
| Media | Operación con baja conectividad | Permitir uso parcial de funciones esenciales sin conexión permanente. |
| Media | Partida multijugador local | Permitir enfrentamientos 1 vs 1 entre dispositivos cercanos. |
| Media | Accesibilidad | Ofrecer interfaz legible, contraste suficiente y elementos adecuados. |
| Baja | Registro de progreso | Almacenar historial básico y avance general sin datos sensibles. |
| Alta | Uso de Items, Effects e Initial Effects | Permitir equipar Items y jugar Effects durante un Clash según las reglas de Class, duración y habilidades. |
| Alta | Partida contra el sistema | Jugar contra un rival controlado por el sistema con dos niveles de dificultad. |
| Media | Mazo inicial | Entregar un mazo inicial válido y un saldo de coins al primer ingreso. |
| Media | Monedas y apertura de sobres | Comprar sobres de cartas con coins según probabilidades por rareza. |
| Media | Intercambio de cartas | Intercambiar cartas al finalizar una partida 1 vs 1 según las reglas del juego físico. |
| Baja | Traducción de habilidades | Mostrar la traducción al español de las habilidades en una ventana emergente. |

## 2.3. Características de los usuarios

| **Tipo de usuario** | **Formación** | **Habilidades** | **Actividades** |
| --- | --- | --- | --- |
| Estudiante | 5° y 6° básico, aproximadamente 10–12 años. | Uso básico de dispositivos móviles, lectura inicial/intermedia en inglés y comprensión de instrucciones simples. | Jugar partidas, armar mazos, revisar cartas, escuchar pronunciación y participar en actividades. |
| Profesor de inglés | Docente responsable del contenido pedagógico. | Manejo básico/intermedio de herramientas digitales, planificación curricular y evaluación de vocabulario. | Gestionar cartas, actualizar vocabulario, generar recompensas, revisar uso y guiar actividades. |

## 2.4. Restricciones

- Plataforma: la versión inicial se ejecutará exclusivamente en dispositivos Android.

- Presupuesto: se privilegiarán tecnologías de bajo costo de operación y mantención. 

- Conectividad: deberá funcionar en contextos con Wi-Fi limitado o inestable, reduciendo consumo de datos y permitiendo uso offline parcial.

- Protección de menores: no deberá solicitar ni almacenar datos personales sensibles como RUT, dirección, teléfono o nombre completo.

- Seguridad: las funciones administrativas estarán disponibles sólo para usuarios autorizados.

- Accesibilidad: se considerarán criterios de legibilidad, contraste y claridad visual alineados con WCAG 2.1 y Ley N° 20.422.

- Propiedad intelectual: se respetará la autoría del juego original, sus reglas, diseños y materiales asociados.

- Rendimiento: la aplicación deberá estar optimizada para dispositivos Android de gama baja o media.

- Idioma: la interfaz y el contenido de las cartas estarán en inglés. El único elemento en español será la traducción de las habilidades, que se muestra en una ventana emergente (RF-14). 

- Alcance pedagógico: el sistema será un apoyo al aprendizaje y no reemplazará la planificación, mediación ni evaluación profesional del docente.

- Multijugador local: el modo 1 vs 1 requerirá que ambos dispositivos se encuentren físicamente cercanos o conectados a la misma red local; no se contempla juego en línea a través de internet en esta versión.

## 2.5. Suposiciones y dependencias

- La contraparte educativa entregará o validará vocabulario, reglas, categorías, atributos y audios del catálogo inicial.

- Los estudiantes dispondrán de tablets Android propias o facilitadas por la institución. 

- La escuela dispondrá de conectividad al menos de forma periódica para sincronizar contenido, actualizaciones o registros básicos.

- El docente responsable administrará los contenidos luego de una capacitación inicial sobre el panel.

- Las reglas principales del juego físico se mantendrán estables durante el desarrollo; cambios significativos deberán registrarse mediante control de versiones.

- Los servicios de backend estarán disponibles y mantendrán costos compatibles con el presupuesto.

- Los recursos gráficos y de audio contarán con autorización, licencia adecuada o creación propia.

- La red del establecimiento o la conexión directa entre dispositivos (Wi-Fi o Bluetooth) permitirá la comunicación entre tablets durante una partida 1 vs 1.

- La primera versión no dependerá de integración directa con sistemas externos de gestión escolar.

- Los dispositivos objetivo contarán con almacenamiento suficiente para cartas, audios esenciales y datos locales mínimos.

## 2.6. Evolución previsible del sistema

- Ampliar el uso a otros niveles educativos.

- Incorporar una versión web o iOS si se requiere mayor cobertura.

- Agregar reportes avanzados para docentes.

- Integrar exportación de datos agregados hacia plataformas institucionales, manteniendo criterios de privacidad.

- Incorporar modos colaborativos, torneos escolares o eventos temporales de recompensa.

- Mejorar opciones de accesibilidad.

- Incorporar nuevas categorías, expansiones temáticas y contenidos curriculares.

- Incorporar partidas en línea entre estudiantes de distintos establecimientos o fuera del colegio, bajo entornos controlados y seguros para menores. 

- Permitir el intercambio de más de una carta al finalizar una partida. 

- Incorporar, en el futuro, un modo de juego para estudiantes con distintas habilidades, por ejemplo con partidas solo de Creatures, sin Items ni Effects, para facilitar su comprensión y participación.

- Validar la pronunciación del estudiante mediante el micrófono del dispositivo.

- Permitir que el profesor configure los valores de la economía, como el costo de los sobres y las probabilidades por Rarity.

- Evaluar recompensas por ganar contra el sistema, manteniendo el control del profesor sobre la entrega de coins y sobres.

# 3. Requisitos específicos

Los siguientes requisitos, redactados conforme al estándar IEEE 830 [1], describen de forma verificable  el comportamiento esperado del sistema. La nomenclatura se ha normalizado para mantener trazabilidad entre la funcionalidad general, los requisitos y los casos de uso.

## 3.1. Requisitos comunes de los interfaces

### 3.1.1. Interfaces de usuario

La aplicación deberá presentar una interfaz gráfica orientada a estudiantes de aproximadamente 10 a 12 años, con iconografía relacionada con la temática de cartas, tipografía legible y controles adecuados para interacción móvil. La interfaz estará íntegramente en inglés; la única excepción es la traducción al español de las habilidades de las cartas. 

| **Interfaz** | **Propósito** | **Elementos / acciones principales** |
| --- | --- | --- |
| Inicio de sesión | Autenticar al usuario y determinar su rol (RF-01). | Nombre de usuario (estudiante); credenciales y PIN de seguridad (profesor); mensaje de error si el acceso falla. |
| Menú principal del estudiante | Centralizar las funciones del estudiante. | Acceso a colección, mazos, partidas, tienda y canje, e historial. |
| Colección | Revisar las cartas del estudiante (RF-03). | Listado de cartas obtenidas y acceso a la vista ampliada de cada una. |
| Vista ampliada de carta | Apoyar el aprendizaje del inglés (RF-05, RF-06, RF-14). | Imagen, nombre en inglés, tipo, Rarity, Class, Power, habilidad y descripción; botón de audio; ventana emergente con la traducción al mantener presionada la habilidad. |
| Gestor de mazos | Construir un mazo válido (RF-03). | Selección y quita de cartas, un Initial Effect, validación de reglas con indicación de la regla incumplida. |
| Selección de modalidad | Elegir cómo jugar (RF-15, RF-16). | Opciones contra el sistema (con nivel Fácil o Normal) y 1 vs 1 local. |
| Conexión 1 vs 1 local | Establecer una partida entre dos tablets (RF-16). | Lista de dispositivos cercanos, envío y respuesta de desafío, selección del mazo activo. |
| Pantalla de partida | Ejecutar el juego (RF-04, RF-10, RF-17). | Cartas reveladas, mano, uso de Items, Effects e Initial Effect, resultado de cada Clash, mazo, Discard Stack y Trophy Stack. |
| Aviso de desconexión | Informar la pausa de una partida 1 vs 1 (RF-18). | Mensaje de pausa para ambos jugadores y tiempo de espera para reconectar. |
| Intercambio de cartas | Realizar el intercambio al final de una partida 1 vs 1 (RF-13). | Cartas del Trophy Stack del ganador, sus propias cartas en el Trophy Stack rival y confirmación. |
| Tienda y canje | Obtener cartas y coins (RF-07, RF-12). | Saldo de coins, compra de sobres, ingreso de códigos y cartas obtenidas. |
| Historial del estudiante | Consultar el progreso (RF-09). | Partidas jugadas, resultados y cartas obtenidas. |
| Panel: catálogo de cartas | Gestionar el catálogo (RF-02). | Listado de cartas, formulario de creación y edición, desactivación. |
| Panel: recompensas | Generar códigos de canje (RF-07). | Cantidad de coins o sobre, número de cuentas que pueden canjearlo. |
| Panel: estadísticas | Consultar el progreso (RF-09). | Partidas jugadas, ganadas y cartas obtenidas, por estudiante y por curso. |

### 3.1.2. Interfaces de hardware

- Dispositivo móvil Android de gama baja o media.

- Pantalla del dispositivo para interacción con la interfaz gráfica.

- Altavoz o salida de audio para reproducir pronunciaciones.

- Almacenamiento local suficiente para cartas, audios y datos de sincronización.

- Conectividad Wi-Fi y/o Bluetooth del dispositivo para el descubrimiento y la comunicación entre tablets en el modo 1 vs 1 local.

### 3.1.3. Interfaces de software

- Sistema operativo Android como plataforma de ejecución de la aplicación móvil.

- Servicio de autenticación para validar credenciales y roles.

- Backend de almacenamiento de datos en la nube para guardar el catálogo de cartas, las colecciones y el progreso de los estudiantes.

- Servicio de almacenamiento de recursos multimedia para audios asociados a cartas.

- Mecanismos de sincronización entre datos locales y backend.

- Servicio de descubrimiento y conexión entre dispositivos cercanos para el modo 1 vs 1 local.

- Base de datos local en el dispositivo para almacenar cartas, mazos, colección y progreso sin conexión.

### 3.1.4. Interfaces de comunicación

- La comunicación entre la aplicación, el panel administrativo y el backend se realizará mediante conexiones cifradas (HTTPS). 

- La sincronización será controlada para minimizar el consumo de datos en contextos de conectividad limitada.

- Cuando no exista conectividad, las operaciones compatibles con modo offline deberán conservar los datos localmente y reintentarse posteriormente.

- Durante una partida 1 vs 1, los dispositivos intercambiarán el estado de la partida directamente entre sí a través de la red local, sin pasar por el servidor ni requerir acceso a internet. 

## 3.2. Requisitos funcionales

### RF-01 — Acceso diferenciado por rol

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-01 |
| Nombre de requisito | Acceso diferenciado por rol |
| Descripción | El sistema debe permitir el ingreso con dos roles: estudiante y profesor. Las cuentas de estudiante serán creadas por el profesor y se identificarán solo con un nombre de usuario, sin solicitar correo, contraseña ni datos personales. El profesor accederá al panel de administración con sus credenciales y un PIN de seguridad. El sistema debe impedir que una cuenta de estudiante acceda a funciones administrativas. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Alta/Esencial |

### RF-02 — Gestión del catálogo de cartas

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-02 |
| Nombre de requisito | Gestión del catálogo de cartas |
| Descripción | El sistema debe permitir al profesor crear, editar, consultar y desactivar cartas de los tipos Creature, Item, Effect e Initial Effect. Cada carta registrará: nombre en inglés, tipo, Rarity, una o más Class, Power o modificador de Power (cuando corresponda), habilidad y duración (si aplica), descripción, imagen, audio de pronunciación y traducción de la habilidad al español. Una carta desactivada dejará de aparecer en sobres y no podrá usarse en partidas; si un estudiante la tiene en su mazo, el sistema le notificará que debe reemplazarla. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Alta/Esencial |

### RF-03 — Colección y construcción de mazos

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-03 |
| Nombre de requisito | Colección y construcción de mazos |
| Descripción | El sistema debe permitir al estudiante visualizar las cartas de su colección y construir un mazo de entre 20 y 25 cartas, más un único Initial Effect , con un máximo de 3 copias de una misma carta. El sistema no permitirá guardar ni usar en partida un mazo que no cumpla estas reglas e indicará cuál regla no se cumple. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Alta/Esencial |

### RF-04 — Ejecución automatizada de partidas

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-04 |
| Nombre de requisito | Ejecución automatizada de partidas |
| Descripción | El sistema debe ejecutar automáticamente las partidas según las reglas del juego físico [6]. . En cada ronda revelará la carta superior del mazo de cada jugador; si no es una Creature, la agregará a la mano del jugador, visible para ambos, y revelará otra. Al enfrentarse dos Creatures (Clash), determinará el resultado en este orden: 1) gana la de mayor Rarity (Legendary > Epic > Rare > Uncommon > Common); 2) si tienen igual Rarity y la misma Class, se produce un empate (Tie); 3) si tienen igual Rarity y distinta Class, gana la de mayor Power, y con igual Power se produce un Tie. Un Tie se resuelve con un nuevo Clash cuyo resultado define el anterior. La Creature ganadora irá al Discard Stack de su dueño y la perdedora al Trophy Stack del ganador; los Items equipados acompañarán a su Creature a la pila que corresponda y los Effects irán al Discard Stack de su dueño al terminar su duración. La partida termina cuando un jugador se queda sin cartas en su mazo y gana quien tenga más cartas en su Trophy Stack contando las Creatures y los Items que las acompañan ; con igual cantidad, la partida termina en empate. Si un Tie no puede resolverse por falta de cartas, las Creatures empatadas volverán al Discard Stack de su dueño y la partida terminará. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Alta/Esencial |

### RF-05 — Apoyo al aprendizaje del inglés

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-05 |
| Nombre de requisito | Apoyo al aprendizaje del inglés |
| Descripción | El sistema debe permitir al estudiante abrir cualquier carta, ya sea en su colección, en el armado de mazos o durante una partida, en una vista ampliada que muestre su imagen, nombre en inglés, tipo, Rarity, Class, Power, habilidad y descripción, junto con la opción de escuchar su pronunciación. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Alta/Esencial |

### RF-06 — Gestión de recursos multimedia

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-06 |
| Nombre de requisito | Gestión de recursos multimedia |
| Descripción | El sistema debe permitir al estudiante reproducir, cuando lo solicite, el audio de pronunciación del nombre de una carta desde su vista ampliada. El audio no se reproducirá de forma automática. Los audios de las cartas de la colección del estudiante deberán estar disponibles sin conexión. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

### RF-07 — Distribución de recompensas

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-07 |
| Nombre de requisito | Distribución de recompensas |
| Descripción | El sistema debe permitir al profesor generar códigos de canje que otorguen una cantidad de coins o un sobre de cartas, pudiendo definir cuántas cuentas pueden canjearlo (por ejemplo, todo un curso). El estudiante ingresará el código en la aplicación para recibir la recompensa. Cada cuenta podrá canjear un mismo código una sola vez; si el código es inválido, ya fue utilizado por esa cuenta o alcanzó su límite de canjes, el sistema informará el error. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

### RF-08 — Operación con baja conectividad

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-08 |
| Nombre de requisito | Operación con baja conectividad |
| Descripción | El sistema debe permitir, sin conexión a internet, jugar partidas contra el sistema y 1 vs 1 local, construir mazos, consultar la colección y reproducir los audios almacenados. El canje de códigos y la actualización del catálogo requerirán conexión. El progreso registrado sin conexión se almacenará localmente y se sincronizará de forma automática al recuperar la conexión. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

### RF-09 — Registro de progreso

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-09 |
| Nombre de requisito | Registro de progreso |
| Descripción | El sistema debe registrar, por estudiante, las partidas jugadas (modalidad, fecha, resultado y trofeos obtenidos) y las cartas obtenidas. El estudiante podrá consultar su historial y el profesor podrá ver estadísticas por estudiante y por curso (partidas jugadas, ganadas y cartas obtenidas), sin almacenar datos personales sensibles. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Baja/Opcional |

### RF-10 — Uso de Items, Effects e Initial Effects

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-10 |
| Nombre de requisito | Uso de Items, Effects e Initial Effects |
| Descripción | Durante un Clash, antes de que se determine el ganador, el sistema debe permitir a cada jugador usar las cartas de su mano: equipar un Item a su Creature en juego, solo si comparten al menos una Class y la Creature no tiene otro Item equipado, salvo que una habilidad indique lo contrario; jugar uno o más Effects, que se aplicarán durante la cantidad de Clashes indicada en la carta; y activar las habilidades activas de su Initial Effect. El Initial Effect estará en juego desde el inicio de la partida. Sus habilidades pasivas se aplicarán automáticamente durante toda la partida; sus habilidades activas podrán activarse una vez por partida, en el momento que el jugador elija durante un Clash. El sistema aplicará los modificadores de Power y las habilidades antes de resolver el Clash e impedirá las jugadas que no cumplan estas reglas. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Alta/Esencial |

### RF-11 — Mazo inicial

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-11 |
| Nombre de requisito | Mazo inicial |
| Descripción | Al ingresar por primera vez, el sistema debe entregar al estudiante un mazo inicial de 22 cartas (21 más un Initial Effect) que cumpla las reglas de RF-03. Todos los estudiantes recibirán la misma cantidad de cartas de cada tipo (Creature, item y Effect), con Rarity asignada al azar, y los items y Effects serán acordes a las Class de las Creatures del mazo, de modo que puedan usarse en partida. Además recibirá un saldo inicial de 100 coins. El mazo inicial quedará guardado en su colección como mazo activo. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

### RF-12 — Monedas y apertura de sobres 

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-12 |
| Nombre de requisito | Monedas y apertura de sobres |
| Descripción | El sistema debe mantener un saldo de coins por estudiante, que solo aumentará con el saldo inicial (RF-11) y los códigos entregados por el profesor (RF-07). El estudiante podrá comprar sobres de 3 cartas a un costo definido por el sistema (por defecto, 50 coins). Las cartas de cada sobre se obtendrán al azar entre las cartas activas del catálogo, según probabilidades por Rarity (por defecto: Common 50 %, Uncommon 25 %, Rare 15 %, Epic 8 %, Legendary 2 %), y se agregarán a la colección del estudiante. Si el saldo es insuficiente, el sistema impedirá la compra e informará al estudiante. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

### RF-13 — Intercambio de cartas al finalizar la partida	

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-13 |
| Nombre de requisito | Intercambio de cartas al finalizar la partida |
| Descripción | Al finalizar una partida 1 vs 1 local con un ganador, el sistema debe permitir al ganador elegir una carta de su Trophy Stack para quedársela y una de sus propias cartas que esté en el Trophy Stack del rival para entregársela al perdedor; el perdedor no elige ninguna carta. Si el Trophy Stack del rival no contiene cartas del ganador, este solo recibirá su carta. Si la partida termina en empate, no habrá intercambio. El intercambio se reflejará en la colección de ambos estudiantes, y si una carta intercambiada formaba parte de un mazo, el sistema notificará a su antiguo dueño que debe completarlo. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

### RF-14 — Traducción de habilidades 

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-14 |
| Nombre de requisito | Traducción de habilidades |
| Descripción | El sistema debe mostrar en una ventana emergente la traducción al español de la habilidad de una carta cuando el estudiante mantenga presionado el texto de dicha habilidad en la vista ampliada. La interfaz y el resto del contenido de las cartas permanecerán en inglés, y no existirá una opción para cambiar el idioma de la aplicación. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Baja/Opcional |

### RF-15 — Partida contra el sistema

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-15 |
| Nombre de requisito | Partida contra el sistema |
| Descripción | El sistema debe permitir al estudiante iniciar una partida contra un rival controlado por el sistema, eligiendo entre dos niveles de dificultad: en el nivel Fácil, el mazo del rival se genera aleatoriamente desde el catálogo sin considerar la correspondencia entre las Class de sus Ítems, Effects y Creatures; en el nivel Normal, sus Items y Effects corresponden a las Class de sus Creatures. En ambos niveles el mazo cumplirá las reglas de RF-03, y el rival usará automáticamente sus Ítems, Effects e Initial Effect cuando sea posible. La partida se ejecutará según RF-04 y no otorgará recompensa. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Alta/Esencial |

### RF-16 — Conexión de partida 1 vs 1 local

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-16 |
| Nombre de requisito | Conexión de partida 1 vs 1 local |
| Descripción | El sistema debe permitir a un estudiante ver los dispositivos cercanos disponibles y enviar un desafío a otro estudiante, quien podrá aceptarlo o rechazarlo. Al aceptarse, ambos seleccionarán su mazo activo y la partida comenzará en los dos dispositivos. La conexión se realizará a través de la red local o directamente entre dispositivos, sin requerir acceso a internet. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

### RF-17 — Sincronización de partida local 

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-17 |
| Nombre de requisito | Sincronización de partida local |
| Descripción | Durante una partida 1 vs 1 local, el sistema debe mantener el mismo estado de la partida en ambos dispositivos: cartas reveladas, cartas en mano, Items y Effects jugados, resultado de cada Clash y contenido de las pilas. Cada acción de un jugador deberá reflejarse en el dispositivo del rival. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

### RF-18 — Manejo de desconexión

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RF-18 |
| Nombre de requisito | Manejo de desconexión |
| Descripción | Si durante una partida 1 vs 1 local uno de los dispositivos pierde la conexión, el sistema debe pausar la partida e informar a ambos jugadores. Si la conexión se recupera dentro de 60 segundos, la partida continuará desde el mismo estado; de lo contrario, se cancelará sin intercambio de cartas ni registro de resultado. |
| Tipo | Requisito |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

## 3.3. Requisitos no funcionales

Los requisitos no funcionales se presentan como condiciones medibles o verificables de calidad y operación del sistema.

### 3.3.1. Requisitos de Rendimiento 

Los siguientes requisitos establecen los tiempos de respuesta y las condiciones mínimas de operación que la aplicación debe cumplir en los dispositivos utilizados en el contexto escolar. 

#### RNF-01 — Tiempos de respuesta 

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RNF-01 |
| Nombre de requisito | Tiempos de respuesta |
| Descripción | El sistema debe cargar el menú principal en un máximo de 3 segundos y resolver cada Clash, incluida la aplicación de Items y Effects, en un máximo de 1 segundo, en al menos el 95 % de los casos, medido en los dispositivos definidos en RNF-03. |
| Tipo | Requisito no funcional |
| Fuente del requisito | Stakeholder |
| Prioridad | Alta/Esencial |

#### RNF-02 — Latencia en partida 1 vs 1 local 

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RNF-02 |
| Nombre de requisito | Latencia en partida 1 vs 1 local |
| Descripción | Durante una partida 1 vs 1 local, cada acción de un jugador debe reflejarse en el dispositivo del rival en un máximo de 1 segundo en al menos el 95 % de los casos, con ambos dispositivos a una distancia de hasta 10 metros. |
| Tipo | Requisito no funcional |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

#### RNF-03 — Rendimiento en dispositivos objetivo 

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RNF-03 |
| Nombre de requisito | Rendimiento en dispositivos objetivo |
| Descripción | La aplicación debe funcionar en tablets Android de gama baja o media con al menos 2 GB de memoria RAM, mantener un mínimo de 30 cuadros por segundo durante la partida y ocupar como máximo 500 MB de almacenamiento, incluidas cartas y audios |
| Tipo | Requisito no funcional |
| Fuente del requisito | Stakeholder |
| Prioridad | Alta/Esencial |

### 3.3.2. Requisitos de Seguridad 

Los siguientes requisitos protegen el sistema frente a accesos no autorizados y resguardan la información de los estudiantes, considerando que los usuarios principales son menores de edad. 

#### RNF-04 — Control de acceso 

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RNF-04 |
| Nombre de requisito | Control de acceso |
| Descripción | Las funciones administrativas deben estar disponibles únicamente para cuentas con rol de profesor autenticadas con sus credenciales y PIN de seguridad. Las contraseñas y los PIN deben almacenarse mediante funciones de hash, y toda comunicación con el servidor debe realizarse mediante HTTPS. El 100 % de los intentos de acceso a funciones administrativas desde cuentas de estudiante deben ser rechazados. |
| Tipo | Requisito no funcional |
| Fuente del requisito | Stakeholder |
| Prioridad | Alta/Esencial |

#### RNF-05 — Protección de datos de menores

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RNF-05 |
| Nombre de requisito | Protección de datos de menores |
| Descripción | El sistema no debe solicitar ni almacenar datos personales sensibles de los estudiantes, como RUT, dirección, teléfono, correo electrónico o nombre completo. Cada estudiante se identificará únicamente mediante un nombre de usuario asignado por el profesor. |
| Tipo | Requisito no funcional |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

### 3.3.3. Requisitos de Fiabilidad

Los siguientes requisitos aseguran que el sistema conserve la información del estudiante ante fallas o interrupciones, considerando la conectividad inestable del contexto escolar. 

#### RNF-06 — Conservación de datos

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RNF-06 |
| Nombre de requisito | Conservación de datos |
| Descripción | El sistema no debe perder la colección, los mazos ni el progreso del estudiante ante cortes de conexión, cierres inesperados de la aplicación o apagado del dispositivo. El 100 % de los cambios confirmados debe conservarse localmente y sincronizarse al recuperar la conexión. Se admitirá como máximo un incidente crítico no resuelto por semestre. |
| Tipo | Requisito no funcional |
| Fuente del requisito | Stakeholder |
| Prioridad | Alta/Esencial |

### 3.3.4. Requisitos de Disponibilidad 

El siguiente requisito define la disponibilidad esperada del sistema, distinguiendo entre las funciones locales y los servicios que dependen del servidor. 

#### RNF-07 — Disponibilidad del sistema 

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RNF-07 |
| Nombre de requisito | Disponibilidad |
| Descripción | Las funciones que operan sin conexión (partidas, mazos, colección y audios almacenados) deben estar disponibles el 100 % del tiempo, independientemente del estado de la red. Los servicios en línea (sincronización, canje de códigos y panel de administración) deben estar disponibles al menos el 99 % del horario escolar, de lunes a viernes entre las 08:00 y las 18:00. |
| Tipo | Requisito no funcional |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

### 3.3.5. Requisitos de Mantenibilidad  

El siguiente requisito establece cómo se mantendrá el sistema y quién podrá realizar cada tipo de mantenimiento.  

#### RNF-08 — Mantenibilidad  

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RNF-08 |
| Nombre de requisito | Mantenibilidad |
| Descripción | El profesor debe poder agregar, modificar o desactivar cartas desde el panel de administración sin requerir cambios en el código ni una nueva versión de la aplicación. El código fuente se mantendrá en un sistema de control de versiones, y las correcciones de errores críticos deberán publicarse en un plazo máximo de 7 días desde su reporte. |
| Tipo | Requisito no funcional |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

### 3.3.6. Requisitos de Portabilidad 

El siguiente requisito define las plataformas en que debe funcionar el sistema y las condiciones para facilitar su traslado a otras plataformas. 

#### RNF-09 — Portabilidad  

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RNF-09 |
| Nombre de requisito | Portabilidad |
| Descripción | La aplicación debe ejecutarse en dispositivos con Android 8.0 o superior y adaptarse a pantallas de tablet de entre 7 y 11 pulgadas. La lógica del juego debe estar separada de la interfaz y del almacenamiento de datos, de modo que pueda reutilizarse en una futura versión para iOS o web. |
| Tipo | Requisito no funcional |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

## 3.4. Otros requisitos 

Esta sección reúne requisitos de accesibilidad, legales y culturales que no corresponden a las categorías anteriores. 

### RNF-10 — Accesibilidad 

| **Campo** | **Especificación** |
| --- | --- |
| Número de requisito | RNF-10 |
| Nombre de requisito | Accesibilidad |
| Descripción | La interfaz debe cumplir los criterios de contraste y legibilidad de WCAG 2.1 nivel AA, con un contraste mínimo de 4,5:1 para el texto, un tamaño de texto mínimo de 14 puntos y elementos táctiles de al menos 48 × 48 dp, conforme a la Ley N° 20.422. |
| Tipo | Requisito no funcional |
| Fuente del requisito | Stakeholder |
| Prioridad | Media/Deseado |

# 4. Apéndices

Los apéndices complementan la especificación mediante una descripción más concreta de las interfaces y los casos de uso del sistema.

## 4.1. Diagrama de casos de uso

Figura 1. Diagrama de casos de uso de Clash of Words.

## 4.2. Especificación de casos de uso

### CU-01 — Resolver Enfrentamiento

| **Campo** | **Especificación** |
| --- | --- |
| Identificador | CU-01 |
| Nombre | Resolver Enfrentamiento |
| Objetivo | Determinar automáticamente el resultado de un Clash entre dos Creatures aplicando las reglas del juego físico. |
| Actores | Estudiante |
| Precondiciones | La partida está iniciada y ambos jugadores tienen una Creature revelada en juego. |
| Suposiciones | Ambos jugadores tuvieron la oportunidad de usar sus Items, Effects e Initial Effects (CU-09). |
| Frecuencia | Alta |
| Flujo básico | 1. El sistema aplica los modificadores de Power y las habilidades de los Items, Effects e Initial Effects activos.  2. Compara la Rarity de ambas Creatures (Legendary > Epic > Rare > Uncommon > Common).  3. Declara ganadora a la Creature de mayor Rarity.  4. Mueve la Creature ganadora, junto con su Item, al Discard Stack de su dueño, salvo que una habilidad le otorgue duración adicional.  5. Mueve la Creature perdedora, junto con su Item, al Trophy Stack del ganador.  6. Descuenta un Clash de la duración de los Effects activos y envía al Discard Stack de su dueño los que terminaron. |
| Flujo(s) alternativo(s) | 2a. Si ambas Creatures tienen igual Rarity y la misma Class, se produce un Tie y se ejecuta Gestionar Desempate (CU-04).  2b. Si tienen igual Rarity y distinta Class, gana la de mayor Power; si el Power también es igual, se produce un Tie y se ejecuta CU-04. |
| Postcondiciones | Las pilas de cartas quedan actualizadas y la partida continúa con la siguiente ronda, o termina si algún mazo quedó vacío. |
| Casos de uso que se incluyen | Ninguno. |
| Casos de uso extendidos | Gestionar Desempate (CU-04); Usar Items, Effects e Initial Effects (CU-09). |
| Notas o comentarios | Corresponde al núcleo del motor de juego (RF-04). |

### CU-02 — Gestionar Catálogo de Cartas

| **Campo** | **Especificación** |
| --- | --- |
| Identificador | CU-02 |
| Nombre | Gestionar Catálogo de Cartas |
| Objetivo | Permitir al profesor crear, editar, consultar y desactivar cartas del catálogo. |
| Actores | Profesor |
| Precondiciones | El profesor está autenticado en el panel de administración. |
| Suposiciones | Existe conexión con el servicio de almacenamiento para registrar la carta. |
| Frecuencia | Baja |
| Flujo básico | 1. El profesor accede al catálogo de cartas y selecciona la opción para agregar una nueva carta.  2. Selecciona el tipo de carta (Creature, Item, Effect o Initial Effect).  3. Ingresa el nombre en inglés y la descripción.  4. Selecciona la Rarity y una o más Class.  5. Ingresa el Power o el modificador de Power, y la habilidad y su duración, según corresponda al tipo de carta. 6. Adjunta la imagen y el audio de pronunciación, e ingresa la traducción de la habilidad al español.  7. Confirma el guardado de la carta.  8. El sistema valida los datos y registra la carta. |
| Flujo(s) alternativo(s) | 1a. Si el profesor selecciona una carta existente, puede editar sus datos o desactivarla; al desactivarla, el sistema la retira de los sobres y de las partidas, y notifica a los estudiantes que la tienen en su mazo.  8a. Si falta un campo obligatorio, el sistema cancela el guardado e indica los campos faltantes. |
| Postcondiciones | La carta queda registrada o actualizada en el catálogo. |
| Casos de uso que se incluyen | Autenticar Administrador (CU-07). |
| Casos de uso extendidos | Ninguno. |
| Notas o comentarios | Corresponde al panel de administración (RF-02). |

### CU-03 — Jugar Partida

| **Campo** | **Especificación** |
| --- | --- |
| Identificador | CU-03 |
| Nombre | Jugar Partida |
| Objetivo | Permitir al estudiante iniciar y desarrollar una partida completa, contra el sistema o contra otro estudiante en modo 1 vs 1 local. |
| Actores | Estudiante |
| Precondiciones | El estudiante inició sesión y tiene un mazo activo válido. |
| Suposiciones | En el modo 1 vs 1 local, ambos dispositivos se encuentran cercanos o en la misma red local. |
| Frecuencia | Alta |
| Flujo básico | 1. El estudiante selecciona la opción para jugar.  2. El sistema muestra las modalidades disponibles: contra el sistema y 1 vs 1 local.  3. El estudiante elige la modalidad contra el sistema.  4. El sistema solicita el nivel de dificultad y el estudiante elige Fácil o Normal.  5. El sistema genera el mazo del rival según el nivel elegido.  6. El sistema baraja el mazo de cada jugador e inicia la partida.  7. En cada ronda, el sistema revela la carta superior de cada mazo; si no es una Creature, la agrega a la mano del jugador y revela otra.  8. Cuando ambos jugadores tienen una Creature revelada, ejecuta Resolver Enfrentamiento (CU-01).  9. Repite los pasos 7 y 8 hasta que un jugador se quede sin cartas en su mazo.  10. Declara ganador a quien tenga más cartas en su Trophy Stack y registra el resultado. |
| Flujo(s) alternativo(s) | 3a. Si el estudiante elige la modalidad 1 vs 1 local, se ejecuta Conectar partida 1 vs 1 local (CU-10) en lugar de los pasos 4 y 5, y el flujo continúa en el paso 6.  9a. En modo 1 vs 1, si un dispositivo pierde la conexión, el sistema pausa la partida; si no se recupera en 60 segundos, la cancela sin registrar resultado ni realizar intercambio.  10a. Si ambos jugadores tienen la misma cantidad de cartas en su Trophy Stack, la partida termina en empate. 10b. En modo 1 vs 1 con un ganador, se ejecuta Intercambiar cartas (CU-11). |
| Postcondiciones | El resultado queda registrado en el historial del estudiante, salvo que la partida haya sido cancelada. |
| Casos de uso que se incluyen | Resolver Enfrentamiento (CU-01). |
| Casos de uso extendidos | Conectar partida 1 vs 1 local (CU-10); Intercambiar cartas (CU-11). |
| Notas o comentarios | Corresponde a RF-04, RF-15, RF-17 y RF-18. La partida contra el sistema no otorga recompensa. |

### CU-04 — Gestionar Desempate

| **Campo** | **Especificación** |
| --- | --- |
| Identificador | CU-04 |
| Nombre | Gestionar Desempate |
| Objetivo | Resolver un Tie mediante un nuevo Clash cuyo resultado define el Clash empatado. |
| Actores | Estudiante |
| Precondiciones | Se produjo un Tie en Resolver Enfrentamiento (CU-01). |
| Suposiciones | Ninguna. |
| Frecuencia | Media |
| Flujo básico | 1. El sistema mantiene en juego las Creatures empatadas.  2. Revela la carta superior de cada mazo hasta que ambos jugadores tengan una nueva Creature.  3. Resuelve el nuevo Clash aplicando las reglas de CU-01.  4. El ganador del nuevo Clash gana también el Clash empatado: las Creatures perdedoras de ambos Clashes van a su Trophy Stack y las ganadoras, al Discard Stack de su dueño. |
| Flujo(s) alternativo(s) | 2a. Si algún jugador no tiene cartas para revelar, las Creatures empatadas vuelven al Discard Stack de su dueño, ningún jugador obtiene trofeo y la partida termina.  3a. Si el nuevo Clash también termina en Tie, se repite el proceso desde el paso 2. |
| Postcondiciones | El Tie queda resuelto y las pilas de cartas, actualizadas. |
| Casos de uso que se incluyen | Ninguno. |
| Casos de uso extendidos | Extiende Resolver Enfrentamiento (CU-01). |
| Notas o comentarios | Corresponde a las reglas de desempate de RF-04. |

### CU-05 — Configurar Mazo

| **Campo** | **Especificación** |
| --- | --- |
| Identificador | CU-05 |
| Nombre | Configurar Mazo |
| Objetivo | Permitir al estudiante construir y guardar un mazo válido con las cartas de su colección. |
| Actores | Estudiante |
| Precondiciones | El estudiante inició sesión y tiene en su colección cartas suficientes para formar un mazo válido. |
| Suposiciones | La colección del estudiante está disponible en el dispositivo. |
| Frecuencia | Alta |
| Flujo básico | 1. El estudiante accede al gestor de mazos. 2. Visualiza las cartas de su colección.  3. Selecciona entre 20 y 25 cartas y un Initial Effect.  4. Confirma el guardado del mazo.  5. El sistema valida las reglas y guarda el mazo como activo. |
| Flujo(s) alternativo(s) | 3a. Si intenta agregar una cuarta copia de una misma carta, el sistema bloquea la selección.  3b. Si intenta agregar un segundo Initial Effect, el sistema bloquea la selección.  5a. Si el mazo no cumple alguna regla, el sistema impide guardarlo e indica la regla incumplida. |
| Postcondiciones | El mazo queda disponible para Jugar Partida. |
| Casos de uso que se incluyen | Ninguno. |
| Casos de uso extendidos | Ninguno. |
| Notas o comentarios | Corresponde a RF-03. El mazo inicial (RF-11) se entrega ya armado. |

### CU-06 — Reproducir Audio de Pronunciación

| **Campo** | **Especificación** |
| --- | --- |
| Identificador | CU-06 |
| Nombre | Reproducir Audio de Pronunciación |
| Objetivo | Permitir que el estudiante escuche la pronunciación en inglés de la palabra asociada a una carta. |
| Actores | Estudiante |
| Precondiciones | El estudiante tiene abierta una carta en vista ampliada. |
| Suposiciones | El audio fue cargado previamente por el profesor. |
| Frecuencia | Alta |
| Flujo básico | 1. El estudiante presiona el botón de audio en la vista ampliada de la carta. 2. El sistema busca el archivo asociado, local o remoto. 3. El sistema reproduce el audio. |
| Flujo(s) alternativo(s) | 2a. Si no existe el archivo local y no hay conexión, el sistema informa que el recurso no puede reproducirse. |
| Postcondiciones | El estudiante escucha la pronunciación disponible. |
| Casos de uso que se incluyen | Ninguno. |
| Casos de uso extendidos | Ninguno. |
| Notas o comentarios | Corresponde a RF-05 y RF-06. El audio no se reproduce de forma automática. |

### CU-07 — Autenticar Administrador

| **Campo** | **Especificación** |
| --- | --- |
| Identificador | CU-07 |
| Nombre | Autenticar Administrador |
| Objetivo | Verificar la identidad del profesor antes de otorgar acceso al panel de administración. |
| Actores | Profesor |
| Precondiciones | El profesor cuenta con una cuenta registrada con rol administrativo. |
| Suposiciones | El servicio de autenticación está disponible. |
| Frecuencia | Media |
| Flujo básico | 1. El profesor ingresa sus credenciales y su PIN de seguridad. 2. El sistema valida las credenciales. 3. Verifica que la cuenta posea rol profesor. 4. Concede acceso al panel. |
| Flujo(s) alternativo(s) | 2a. Si las credenciales o el PIN son inválidos, el sistema informa el error.  3a. Si la cuenta no posee rol administrativo, deniega el acceso. |
| Postcondiciones | El profesor accede con los permisos correspondientes. |
| Casos de uso que se incluyen | Ninguno. |
| Casos de uso extendidos | Ninguno. |
| Notas o comentarios | Es incluido por Gestionar Catálogo de Cartas y Ver Estadísticas de Progreso. |

### CU-08 — Ver Estadísticas de Progreso

| **Campo** | **Especificación** |
| --- | --- |
| Identificador | CU-08 |
| Nombre | Ver Estadísticas de Progreso |
| Objetivo | Permitir al profesor consultar las partidas y cartas obtenidas por estudiante y por curso. |
| Actores | Profesor |
| Precondiciones | El profesor está autenticado en el panel. |
| Suposiciones | Existen registros previamente almacenados. |
| Frecuencia | Baja |
| Flujo básico | 1. El profesor selecciona la opción de estadísticas de progreso.  2. El sistema consulta registros agregados.  3. Despliega, por estudiante o por curso, las partidas jugadas, las partidas ganadas y las cartas obtenidas. |
| Flujo(s) alternativo(s) | 2a. Si no existen registros para el periodo consultado, muestra un mensaje indicando que no hay datos disponibles. |
| Postcondiciones | El profesor obtiene información para orientar su planificación pedagógica. |
| Casos de uso que se incluyen | Autenticar Administrador (CU-07). |
| Casos de uso extendidos | Ninguno. |
| Notas o comentarios | La información corresponde a datos agregados y no sensibles. |

### CU-09 — Usar Items, Effects e Initial Effects 

| **Campo** | **Especificación** |
| --- | --- |
| Identificador | CU-09 |
| Nombre | Usar Items, Effects e Initial Effects |
| Objetivo | Permitir al estudiante usar las cartas de su mano y su Initial Effect durante un Clash. |
| Actores | Estudiante |
| Precondiciones | Hay un Clash en curso y el estudiante tiene cartas en su mano o un Initial Effect con habilidad activa que aún no haya usado |
| Suposiciones | Ninguna. |
| Frecuencia | Alta |
| Flujo básico | 1.El estudiante selecciona un Item de su mano.  2. El sistema verifica que el Item comparta al menos una Class con la Creature en juego y que esta no tenga otro Item equipado.  3. El sistema equipa el Item y aplica su modificador de Power y su habilidad.  4. El estudiante confirma que terminó de usar sus cartas; cuando ambos jugadores confirman, el sistema continúa con Resolver Enfrentamiento (CU-01). |
| Flujo(s) alternativo(s) | 1a. Si el estudiante selecciona un Effect, el sistema lo aplica durante la cantidad de Clashes indicada en la carta.  1b. Si el estudiante activa su Initial Effect, el sistema aplica su habilidad (una vez por partida) . 1c: Si el estudiante ya usó su Initial Effect en la partida, el sistema impide activarlo de nuevo e informa el motivo. 2a. Si el Item no cumple las reglas, el sistema impide equiparlo e informa el motivo. |
| Postcondiciones | Los modificadores y habilidades quedan aplicados para el Clash en curso. |
| Casos de uso que se incluyen | Ninguno. |
| Casos de uso extendidos | Extiende Resolver Enfrentamiento (CU-01). |
| Notas o comentarios | Corresponde a RF-10. En la partida contra el sistema, el rival usa sus cartas de forma automática (RF-15). |

### CU-10 — Conectar partida 1 vs 1 local 

| **Campo** | **Especificación** |
| --- | --- |
| Identificador | CU-10 |
| Nombre | Conectar partida 1 vs 1 local |
| Objetivo | Establecer una partida entre dos dispositivos cercanos sin requerir acceso a internet. |
| Actores | Estudiante (retador), Estudiante (rival) |
| Precondiciones | Ambos estudiantes iniciaron sesión, tienen un mazo activo válido y seleccionaron la modalidad 1 vs 1 local |
| Suposiciones | Los dispositivos están cercanos o en la misma red local y tienen Wi-Fi o Bluetooth activado. |
| Frecuencia | Media |
| Flujo básico | 1. El sistema muestra los dispositivos cercanos disponibles.  2. El retador selecciona a un rival y le envía un desafío.  3. El rival acepta el desafío.  4. El sistema establece la conexión entre ambos dispositivos.  5. Ambos estudiantes confirman su mazo activo y la partida comienza en los dos dispositivos. |
| Flujo(s) alternativo(s) | 1a. Si no hay dispositivos disponibles, el sistema lo informa y permite buscar nuevamente.  3a. Si el rival rechaza el desafío o no responde, el sistema informa al retador y vuelve a la lista de dispositivos.  4a. Si la conexión falla, el sistema informa el error y permite reintentar. |
| Postcondiciones | La partida queda iniciada y sincronizada en ambos dispositivos. |
| Casos de uso que se incluyen | Ninguno. |
| Casos de uso extendidos | Extiende Jugar Partida (CU-03). |
| Notas o comentarios | Corresponde a RF-16 y RF-17. |

### CU-11 — Intercambiar cartas 

| **Campo** | **Especificación** |
| --- | --- |
| Identificador | CU-11 |
| Nombre | Intercambiar cartas |
| Objetivo | Realizar el intercambio de cartas al finalizar una partida 1 vs 1 local, según las reglas del juego físico. |
| Actores | Estudiante ganador, Estudiante perdedor |
| Precondiciones | Finalizó una partida 1 vs 1 local con un ganador. |
| Suposiciones | Ambos dispositivos siguen conectados. |
| Frecuencia | Media |
| Flujo básico | 1. El sistema muestra al ganador las cartas de su Trophy Stack.  2. El ganador elige la carta que se quedará.  3. El sistema muestra al ganador sus propias cartas que están en el Trophy Stack del rival.  4. El ganador elige la carta que entregará al perdedor.  5. El sistema actualiza la colección de ambos estudiantes y muestra el resultado del intercambio. |
| Flujo(s) alternativo(s) | 3a. Si el Trophy Stack del rival no contiene cartas del ganador, el sistema omite los pasos 3 y 4.  5a. Si una carta intercambiada formaba parte de un mazo, el sistema notifica a su antiguo dueño que debe completarlo. |
| Postcondiciones | Las colecciones de ambos estudiantes quedan actualizadas. |
| Casos de uso que se incluyen | Ninguno. |
| Casos de uso extendidos | Extiende Jugar Partida (CU-03). |
| Notas o comentarios | Corresponde a RF-13. El perdedor no elige ninguna carta. |

		Proyecto de Investigación e Innovación  |