# AI Semantic Mobile App

Aplicacion movil Flutter para asistencia tecnica y cientifica en el uso de
cascarilla de cafe para purificacion de agua.

El proyecto esta separado en frontend y backend para mantener modularidad,
escalar integraciones IA y facilitar evolucion hacia flujos RAG con bases de
datos vectoriales.

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
│   │   │   └── search
│   │   │       ├── data
│   │   │       │   └── search_repository.dart
│   │   │       ├── domain
│   │   │       │   └── semantic_result.dart
│   │   │       └── presentation
│   │   │           └── search_page.dart
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── backend
│   ├── lib
│   │   ├── server.dart
│   │   ├── api
│   │   │   ├── routes.dart
│   │   │   └── handlers
│   │   │       ├── chat_handler.dart
│   │   │       └── search_handler.dart
│   │   ├── ai
│   │   │   ├── embeddings_client.dart
│   │   │   └── llm_client.dart
│   │   ├── vector_db
│   │   │   ├── pinecone_client.dart
│   │   │   └── semantic_index_service.dart
│   │   └── models
│   │       ├── chat_request.dart
│   │       └── search_request.dart
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── .gitignore
└── README.md
```

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Ollama (opcional, para inferencia local)
- Token de Hugging Face (opcional, para inferencia en la nube)

### Running the Application

1. Inicia el backend:

```
cd backend
dart pub get
dart run lib/server.dart
```

2. Inicia la app Flutter:

```
cd frontend
flutter pub get
flutter run --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8080
```

Para iOS simulador usa normalmente `http://localhost:8080`.

## Conexion a Llama

### Opcion 1: Ollama (local)

1. Asegura que Ollama este activo y con modelo disponible:

```
ollama pull llama3
ollama serve
```

2. Desde la app selecciona proveedor `Ollama` y modelo `llama3`.

3. El backend invoca `POST /api/generate` de Ollama.

### Opcion 2: Hugging Face (API Inference)

1. Exporta tu token y levanta backend:

```
cd backend
dart run \
  -DHUGGING_FACE_API_TOKEN=tu_token \
  -DHUGGING_FACE_MODEL=meta-llama/Meta-Llama-3-8B-Instruct \
  lib/server.dart
```

2. En la app selecciona proveedor `Hugging Face`.

3. Puedes cambiar el modelo en el campo `Modelo Llama`.

## Busqueda Semantica (RAG)

El flujo RAG usa:

- Embeddings (`Ollama` o `Hugging Face`) para vectorizar la consulta.
- Pinecone para recuperar contexto relevante.
- Llama para generar la respuesta final usando los contextos recuperados.

Endpoint backend:

```
POST /semantic-search
```

Payload ejemplo:

```json
{
  "query": "Como producir biochar con cascarilla de cafe?",
  "topK": 4,
  "provider": "ollama",
  "model": "llama3"
}
```

Variables de entorno recomendadas para Pinecone:

```
-DPINECONE_API_KEY=tu_api_key
-DPINECONE_INDEX_HOST=tu-indice-xxxx.svc.xxx.pinecone.io
-DPINECONE_NAMESPACE=opcional
```

Variables para embeddings:

```
-DEMBEDDING_PROVIDER=ollama|huggingface
-DOLLAMA_EMBEDDING_MODEL=nomic-embed-text
-DHUGGING_FACE_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

## Indexador JSON (backend)

Se incluyo un indexador que acepta unicamente archivos `.json` para cargar
documentos a Pinecone.

Ejecucion:

```
cd backend
dart run bin/index_json.dart <ruta/dataset.json> [batchSize]
```

Variables requeridas para indexar en Pinecone:

```
-DPINECONE_API_KEY=tu_api_key
-DPINECONE_INDEX_HOST=tu-indice-xxxx.svc.xxx.pinecone.io
```

Formatos JSON aceptados:

1. Arreglo directo de documentos:

```json
[
  {
    "id": "doc-1",
    "title": "Biochar basico",
    "text": "Contenido tecnico del documento",
    "source": "manual-campo"
  }
]
```

2. Objeto con clave `documents`:

```json
{
  "documents": [
    {
      "id": "doc-2",
      "title": "Filtro multicapa",
      "text": "Contenido tecnico del documento",
      "source": "guia-tecnica"
    }
  ]
}
```

Notas:

- Si falta `id`, se genera uno automatico.
- Si falta `title` o `source`, se asignan valores por defecto.
- El campo principal recomendado es `text` (tambien se acepta `chunk`).

## Mockup Implementado

- Pantalla de chat con estilo visual enfocado en contexto caficultor.
- Pantalla RAG para busqueda semantica y visualizacion de contextos recuperados.
- Selector de proveedor IA (Ollama/Hugging Face).
- Campo editable de modelo (por ejemplo `llama3` o
  `meta-llama/Meta-Llama-3-8B-Instruct`).
- Flujo completo de pregunta-respuesta hacia backend (`/chat`).

## Features

- Chat conversacional para asistencia tecnica.
- Integracion con Llama via Ollama o Hugging Face.
- Base preparada para evolucion a RAG + vector database.

