# Clash of Words

Aplicación móvil educativa para tablets Android que digitaliza el juego de cartas físico *Clash of Words*, creado por el profesor Orlando Muñoz para estudiantes de 5° y 6° básico. El juego apoya el aprendizaje de vocabulario en inglés, la comprensión lectora, la expresión oral y la convivencia escolar.

Proyecto del ramo Proyecto de Investigación e Innovación, Universidad de La Frontera.

Los requisitos completos están en [docs/SRS.md](docs/SRS.md).

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) 3.41 o superior (incluye Dart 3.11).
- Android SDK, instalado con Android Studio.
- Un emulador de tablet o una tablet con Android 8.0 o superior.

Para revisar que todo esté instalado:

```bash
flutter doctor
```

## Cómo empezar

```bash
git clone https://github.com/Ertrax147/ClashOfWords.git
cd ClashOfWords
flutter pub get
flutter run
```

`flutter pub get` instala las dependencias de la app y del motor del juego de una sola vez, porque el proyecto es un *workspace* de Dart.

## Cómo correr los tests

Tests de la app:

```bash
flutter test
```

Tests del motor del juego:

```bash
cd packages/game_engine
dart test
```

Antes de abrir un Pull Request, además, el análisis estático debe pasar sin errores:

```bash
flutter analyze
```

## Estructura del proyecto

```
ClashOfWords/
├── docs/                  Documentación (SRS)
├── packages/
│   └── game_engine/       Motor del juego en Dart puro
├── lib/                   App Flutter
│   ├── main.dart
│   ├── app.dart
│   ├── core/              Tema, rutas, inyección de dependencias
│   ├── features/          Una carpeta por funcionalidad
│   └── shared/            Widgets y utilidades comunes
├── test/                  Tests de la app
└── android/               Configuración de Android
```

Algunas carpetas todavía no existen: se crean a medida que se implementa cada funcionalidad.

### Motor del juego (`packages/game_engine`)

Contiene las reglas del juego: cartas, resolución de Clash, Items, Effects, pilas y fin de partida. Está escrito en Dart puro y **no puede depender de Flutter**, de la interfaz ni del almacenamiento (RNF-09). Así se puede probar por sí solo y reutilizar en otras plataformas. Un test falla si alguien agrega Flutter como dependencia del motor.

### App (`lib/`)

Sigue clean architecture, organizada por funcionalidad. Cada carpeta dentro de `features/` tiene tres capas:

- `domain/`: qué necesita la funcionalidad, expresado como interfaces de repositorio y casos de uso. No conoce Flutter ni la base de datos.
- `data/`: cómo se obtienen y guardan los datos. Implementa los repositorios y contiene los *models*, que convierten los datos guardados en entidades del juego.
- `presentation/`: pantallas, widgets y estado de la interfaz.

El estado se maneja con [Riverpod](https://riverpod.dev).

La interfaz va íntegramente en inglés. Lo único en español es la traducción de las habilidades.

## Flujo de trabajo

- `main`: versión estable. Solo recibe merges desde `dev`.
- `dev`: rama de integración.
- `feature/<nombre>`, `fix/<nombre>`, `docs/<nombre>`: una rama por tarea, creada desde `dev` y unida a `dev` mediante Pull Request.

Los commits son pequeños, en español y con prefijo: `feat:`, `fix:`, `docs:`, `refactor:`, `test:` o `chore:`. Cuando corresponde, se cita el requisito implementado, por ejemplo `feat: resuelve Clash por Rarity (RF-04)`.

Antes de abrir un Pull Request, los tests deben pasar y `flutter analyze` no debe mostrar errores. No se hace force push a `main` ni a `dev`.

## Problemas conocidos

### Windows: `Unable to establish loopback connection` al compilar

Gradle falla con este error en algunos equipos Windows, sobre todo cuando el nombre de usuario tiene espacios. Para resolverlo:

1. Crea la carpeta `C:\temp`.
2. Abre "Editar las variables de entorno de esta cuenta" desde el menú Inicio.
3. Agrega una variable de usuario llamada `JAVA_TOOL_OPTIONS` con el valor `-Djdk.net.unixdomain.tmpdir=C:\temp`.
4. Cierra y vuelve a abrir la terminal y el editor.
