# AI Semantic Mobile App

Aplicacion movil Flutter para asistencia tecnica y cientifica en el uso de
cascarilla de cafe para purificacion de agua.

El proyecto esta separado en frontend y backend para mantener modularidad,
escalar integraciones IA y facilitar mantenimiento del flujo de chat.

## Project Structure

```
ai-semantic-mobile-app
├── frontend
│   ├── lib
│   │   ├── core
│   │   │   ├── config
│   │   │   │   └── app_config.dart
│   │   │   ├── network
│   │   │   │   └── api_client.dart
│   │   │   └── services
│   │   │       └── ai_service.dart
│   │   ├── features
│   │   │   ├── chat
│   │   │   │   ├── data
│   │   │   │   │   └── chat_repository.dart
│   │   │   │   ├── domain
│   │   │   │   │   └── chat_message.dart
│   │   │   │   └── presentation
│   │   │   │       └── chat_page.dart
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── backend
│   ├── lib
│   │   ├── server.dart
│   │   ├── api
│   │   │   ├── routes.dart
│   │   │   └── handlers
│   │   │       └── chat_handler.dart
│   │   ├── ai
│   │   │   └── llm_client.dart
│   │   └── models
│   │       └── chat_request.dart
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── .gitignore
└── README.md
```

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- API key de Gemini

### Running the Application

1. Inicia el backend:

```
cd backend
dart pub get
cp .env.example .env
set -a
source .env
set +a
dart run lib/server.dart
```

2. Inicia la app Flutter:

```
cd frontend
flutter pub get
flutter run --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8080
```

Para iOS simulador usa normalmente `http://localhost:8080`.

## Conexion a LLM

### Opcion 0: Gemini (API)

1. Configura `.env` en `backend`:

```
GEMINI_API_KEY=tu_api_key
GEMINI_MODEL=gemini-1.5-flash
```

2. Levanta backend usando variables de `.env`:

```
cd backend
set -a
source .env
set +a
dart run lib/server.dart
```

3. Abre la app y envia tu pregunta desde el chat. El backend usa Gemini por
   defecto.

## Mockup Implementado

- Pantalla de chat con estilo visual enfocado en contexto caficultor.
- Flujo simplificado sin selector de proveedor o modelo.
- Flujo completo de pregunta-respuesta hacia backend (`/chat`).

## Features

- Chat conversacional para asistencia tecnica.
- Integracion directa con Gemini API.
- Mensajes de debug para validar conexion backend/Gemini.

