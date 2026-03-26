import os
import pandas as pd
from pinecone import Pinecone, ServerlessSpec
from tqdm import tqdm
from sentence_transformers import SentenceTransformer

# Cargar .env desde la carpeta del script
from dotenv import load_dotenv
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), ".env"))

# 1. Inicializar modelo de embeddings local
model = SentenceTransformer('all-MiniLM-L6-v2')

PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
INDEX_NAME = "cafe"  
PINECONE_CLOUD = os.getenv("PINECONE_CLOUD", "aws")  # Ajusta si usas otro cloud
PINECONE_REGION = os.getenv("PINECONE_REGION", "us-east-1")  # Región gratuita por defecto
assert PINECONE_API_KEY, "Falta PINECONE_API_KEY en .env"


# 2. Inicializar cliente Pinecone
pc = Pinecone(api_key=PINECONE_API_KEY)

# 3. Crear el índice en Pinecone si no existe
if INDEX_NAME not in pc.list_indexes().names():
    print(f"Creando índice '{INDEX_NAME}' en Pinecone...")
    pc.create_index(
        name=INDEX_NAME,
        dimension=384,  # all-MiniLM-L6-v2 produce vectores de 384 dimensiones
        metric="cosine",
        spec=ServerlessSpec(
            cloud=PINECONE_CLOUD,
            region=PINECONE_REGION
        )
    )
else:
    print(f"Índice '{INDEX_NAME}' ya existe.")

# 4. Conectar al índice
index = pc.Index(INDEX_NAME)

# 5. Leer el CSV
csv_path = "adsorcion_carbono_db.csv"  # Cambia si tu archivo tiene otro nombre
df = pd.read_csv(csv_path)

# 6. Función para obtener embedding de un texto
def get_embedding(text):
    return model.encode(text).tolist()

# Función para asegurar que el ID es ASCII
import unicodedata
def make_ascii_id(text):
    # Convierte a string, elimina acentos y caracteres no ASCII
    return unicodedata.normalize('NFKD', str(text)).encode('ascii', 'ignore').decode('ascii')

# 7. Subir los datos a Pinecone
batch_size = 32
vectors = []


print("Generando embeddings y subiendo a Pinecone...")
total_uploaded = 0
for i, row in tqdm(df.iterrows(), total=len(df)):
    try:
        text = str(row.to_dict())
        meta = {k: ("" if pd.isna(v) else v) for k, v in row.to_dict().items()}
        vector_id = make_ascii_id(f"id-{i}")
        vectors.append((vector_id, get_embedding(text), meta))
    except Exception as e:
        print(f"[ERROR] Fila {i} no procesada: {e}")
    # Subir en lotes
    if len(vectors) == batch_size or i == len(df) - 1:
        print(f"Subiendo lote de {len(vectors)} vectores (hasta fila {i})...")
        try:
            index.upsert(vectors)
            total_uploaded += len(vectors)
        except Exception as e:
            print(f"[ERROR] Fallo al subir lote: {e}")
            # Intentar subir cada vector individualmente
            for v in vectors:
                try:
                    index.upsert([v])
                    total_uploaded += 1
                except Exception as ve:
                    print(f"[ERROR] Vector no subido: {v[0]} | {ve}")
        vectors = []
print(f"Total de vectores subidos: {total_uploaded}")

print("¡Listo! Todos los datos han sido subidos a Pinecone.")

# 8. (Opcional) Verifica que los datos están en el índice
print("Total de vectores en el índice:", index.describe_index_stats()["total_vector_count"])
