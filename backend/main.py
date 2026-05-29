from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
from google.api_core import exceptions as google_exceptions
from dotenv import load_dotenv
import os
import io
import json
import re
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

# Request schema — Chat
class Question(BaseModel):
    question: str


# Request schema — Estimasi Panen
class HarvestInput(BaseModel):
    luas_lahan: float      # meter persegi
    umur_tanaman: int      # hari
    jumlah_bibit: int      # jumlah bibit
    kondisi_tanaman: str   # Baik / Sedang / Buruk


# ─── Helper: klasifikasi error Gemini/network → pesan Indonesia ───────────────
def _gemini_error_message(e: Exception) -> str:
    """Mengembalikan pesan error yang ramah pengguna tanpa stack trace."""
    err_str = str(e).lower()

    # 429 — Quota / Rate Limit
    if (
        isinstance(e, google_exceptions.ResourceExhausted)
        or "quota" in err_str
        or "resource exhausted" in err_str
        or "429" in err_str
        or "rate limit" in err_str
    ):
        return (
            "Kuota AI sedang habis atau terlalu banyak permintaan. "
            "Silakan coba lagi beberapa saat lagi."
        )

    # Timeout / Deadline
    if (
        isinstance(e, google_exceptions.DeadlineExceeded)
        or "deadline exceeded" in err_str
        or "timeout" in err_str
        or "timed out" in err_str
    ):
        return (
            "AI membutuhkan waktu terlalu lama untuk merespons. "
            "Silakan coba lagi."
        )

    # 503 — Service Unavailable
    if (
        isinstance(e, google_exceptions.ServiceUnavailable)
        or "unavailable" in err_str
        or "503" in err_str
    ):
        return (
            "Layanan AI sedang tidak tersedia sementara. "
            "Silakan coba beberapa saat lagi."
        )

    # Koneksi / Network
    if (
        isinstance(e, (ConnectionError, OSError))
        or "connection" in err_str
        or "network" in err_str
    ):
        return (
            "Gagal terhubung ke layanan AI. "
            "Periksa koneksi internet Anda dan coba lagi."
        )

    # Fallback — jangan ekspos detail teknis
    return "Terjadi kesalahan pada AI. Silakan coba lagi."


@app.get("/")
def home():
    return {
        "message": "Panen Cerdas AI API Running 🚀"
    }


@app.post("/chat")
async def chat(data: Question):

    try:
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
        return {"success": True, "answer": response.text}

    except Exception as e:
        return {"success": False, "message": _gemini_error_message(e)}


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
        return {"success": True, "result": response.text}

    except PIL.UnidentifiedImageError:
        return {
            "success": False,
            "message": "File yang diunggah bukan gambar yang valid. Pastikan file berformat JPG atau PNG."
        }
    except Exception as e:
        return {"success": False, "message": _gemini_error_message(e)}


@app.post("/estimate-harvest")
async def estimate_harvest(data: HarvestInput):

    try:
        prompt = f"""
        Kamu adalah AI ahli pertanian bawang merah di Indonesia.

        Buat estimasi panen berdasarkan data lahan berikut:
        - Luas lahan      : {data.luas_lahan} m²
        - Umur tanaman    : {data.umur_tanaman} hari
        - Jumlah bibit    : {data.jumlah_bibit} bibit
        - Kondisi tanaman : {data.kondisi_tanaman}

        Informasi referensi:
        - Bawang merah umumnya panen pada usia 60–70 hari setelah tanam
        - Produktivitas rata-rata: 0.8–1.2 kg/m² (tergantung kondisi)
        - Kondisi Baik = 1.1 kg/m², Sedang = 0.9 kg/m², Buruk = 0.6 kg/m²

        Berikan respons HANYA dalam format JSON berikut.
        Jangan tambahkan teks, penjelasan, atau markdown apapun di luar JSON:
        {{
            "estimasi_hari_panen": "string deskripsi (contoh: 15 hari lagi, atau Sudah siap panen)",
            "estimasi_hasil_kg": angka_numerik_tanpa_satuan,
            "tingkat_risiko": "Rendah atau Sedang atau Tinggi",
            "faktor_risiko": "penjelasan singkat 1 kalimat",
            "rekomendasi": [
                "tindakan konkret 1",
                "tindakan konkret 2",
                "tindakan konkret 3",
                "tindakan konkret 4"
            ],
            "catatan_penting": "catatan tambahan singkat untuk petani"
        }}
        """

        response = model.generate_content(prompt)
        text = response.text.strip()

        # Bersihkan markdown code block jika ada
        text = re.sub(r'```json\s*', '', text)
        text = re.sub(r'```\s*', '', text)
        text = text.strip()

        # Coba parse JSON langsung
        try:
            result = json.loads(text)
            return {"success": True, "status": "success", "data": result}
        except json.JSONDecodeError:
            pass

        # Fallback: ekstrak JSON dari teks menggunakan regex
        json_match = re.search(r'\{.*\}', text, re.DOTALL)
        if json_match:
            try:
                result = json.loads(json_match.group())
                return {"success": True, "status": "success", "data": result}
            except json.JSONDecodeError:
                pass

        # Fallback terakhir: kembalikan teks mentah
        return {"success": True, "status": "fallback", "raw": text}

    except Exception as e:
        return {"success": False, "message": _gemini_error_message(e)}