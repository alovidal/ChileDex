# **Carpeta FEATURES**

## Propósito:

Esta carpeta tiene como propósito contener módulo del sistema que se encarga de realizar una función específica y su propia capa de presentación, dominio y datos.

## Ejemplo:

├── auth/
│   │   ├── presentation/         # Widgets, Screens, Controllers/Cubits propios del módulo
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   └── controllers/
│   │   ├── domain/               # Entidades, casos de uso, interfaces
│   │   │   ├── entities/
│   │   │   ├── usecases/
│   │   │   └── repositories/     # Solo interfaces (abstract class)
│   │   └── data/                 # Implementaciones concretas
│   │       ├── models/           # DTOs / mappers desde/hacia JSON
│   │       ├── repositories/     # Implementa las interfaces de domain
│   │       └── datasources/      # Supabase, API calls, caché local