from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
from dotenv import load_dotenv
import os
import io
import PIL.Image

# Load environment variables
load_dotenv()

# FastAPI app
app = FastAPI()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure Gemini API
genai.configure(
    api_key=os.getenv("GEMINI_API_KEY")
)

# Gemini Model
model = genai.GenerativeModel(
    "gemini-2.5-flash"
)

# Request schema
class Question(BaseModel):
    question: str


@app.get("/")
def home():
    return {
        "message": "Panen Cerdas AI API Running 🚀"
    }


@app.post("/chat")
async def chat(data: Question):

    prompt = f"""
    Kamu adalah AI ahli pertanian bawang merah di Indonesia.

    Tugas kamu:
    - membantu petani bawang merah
    - memberi solusi penyakit tanaman
    - memberi rekomendasi pupuk
    - membantu estimasi panen
    - gunakan bahasa sederhana

    Pertanyaan:
    {data.question}
    """

    response = model.generate_content(prompt)

    return {
        "answer": response.text
    }


@app.post("/analyze-image")
async def analyze_image(file: UploadFile = File(...)):

    try:
        # Baca bytes gambar dari upload
        image_bytes = await file.read()
        image = PIL.Image.open(io.BytesIO(image_bytes))

        prompt = """
        Kamu adalah AI ahli pertanian bawang merah di Indonesia.

        Analisis gambar tanaman bawang merah berikut secara menyeluruh dan berikan laporan dalam format ini:

        ## 🔍 Identifikasi Penyakit / Masalah
        Sebutkan nama penyakit atau masalah yang terdeteksi pada tanaman.

        ## 🌿 Gejala yang Terdeteksi
        Deskripsi gejala visual yang terlihat pada tanaman dalam gambar.

        ## ⚠️ Penyebab
        Jelaskan penyebab penyakit atau masalah tersebut (jamur, bakteri, hama, kekurangan nutrisi, dll).

        ## ✅ Solusi Penanganan
        Langkah-langkah konkret dan praktis untuk mengatasi masalah:
        1. Tindakan segera
        2. Tindakan jangka menengah
        3. Tindakan jangka panjang

        ## 💊 Rekomendasi Pupuk & Pestisida
        Sebutkan nama produk atau bahan aktif yang direkomendasikan beserta dosis dan cara aplikasinya.

        ## 🛡️ Pencegahan
        Tips mencegah masalah serupa di masa depan.

        Gunakan bahasa Indonesia yang sederhana dan mudah dipahami petani.
        Jika gambar tidak menampilkan tanaman bawang merah atau gambar tidak jelas,
        sampaikan dengan sopan dan minta pengguna untuk mengunggah foto yang lebih jelas.
        """

        response = model.generate_content([prompt, image])
        return {"result": response.text}

    except PIL.UnidentifiedImageError:
        raise HTTPException(
            status_code=400,
            detail="File yang diunggah bukan gambar yang valid."
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Terjadi kesalahan saat menganalisis gambar: {str(e)}"
        )