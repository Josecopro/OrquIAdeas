# Instrucciones para el pipeline RAG con Pinecone y OpenAI

1. Copia el archivo `.env.example` a `.env` y coloca tus claves reales.
2. Instala las dependencias:
   
   ```bash
   pip install -r rag_scripts/requirements.txt
   ```
3. Coloca tu archivo `adsorcion_carbono_db.csv` en la raíz del proyecto (o ajusta la ruta en el script).
4. Ejecuta el script de ingesta:
   
   ```bash
   python rag_scripts/ingest_csv_to_pinecone.py
   ```
5. El script creará el índice en Pinecone (si no existe), generará los embeddings y subirá los datos.

**Notas:**
- El nombre del índice por defecto es `cafe`. Puedes cambiarlo en el script si lo deseas.
- El environment de Pinecone lo encuentras en el dashboard de Pinecone.
- El script asume que cada fila del CSV es un documento. Si necesitas un procesamiento especial, ajusta la línea donde se genera el texto para el embedding.
