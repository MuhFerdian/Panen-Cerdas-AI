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


# ─── Offline Fallback: /chat (rule-based berbasis kata kunci) ──────────────
_CHAT_RULES: list[tuple[tuple[str, ...], str]] = [
    (
        ('penyakit', 'sakit', 'layu', 'busuk', 'jamur', 'bercak', 'kuning', 'mati'),
        """**Penyakit Umum Bawang Merah & Penanganannya**

**1. Layu Fusarium**
- Gejala: Daun menguning dan layu dari bawah
- Solusi: Cabut tanaman terinfeksi, aplikasi fungisida karbendazim

**2. Bercak Ungu (Alternaria porri)**
- Gejala: Bercak coklat-ungu pada daun
- Solusi: Semprot mancozeb 80% dosis 2 g/L air

**3. Busuk Umbi (Botrytis)**
- Gejala: Umbi membusuk, berwarna coklat
- Solusi: Perbaiki drainase, kurangi kelembaban

> ⚠️ *Jawaban ini dihasilkan secara offline. Hubungi penyuluh pertanian untuk diagnosis lebih akurat.*""",
    ),
    (
        ('hama', 'ulat', 'trips', 'thrips', 'kutu', 'lalat', 'serangga'),
        """**Hama Umum Bawang Merah & Pengendaliannya**

**1. Trips (Thrips tabaci)**
- Gejala: Bintik perak pada daun, daun mengkerut
- Solusi: Spinosad 25 SC dosis 1 mL/L atau imidakloprid

**2. Ulat Bawang (Spodoptera exigua)**
- Gejala: Daun berlubang, terlihat kotoran ulat
- Solusi: Bacillus thuringiensis atau klorpirifos 20 EC

**3. Lalat Pengorok Daun**
- Gejala: Alur putih berliku di daun
- Solusi: Abamektin 18 EC dosis 0.5 mL/L

> ⚠️ *Jawaban ini dihasilkan secara offline. Hubungi penyuluh pertanian untuk diagnosis lebih akurat.*""",
    ),
    (
        ('pupuk', 'pemupukan', 'nutrisi', 'urea', 'npk', 'unsur hara'),
        """**Panduan Pemupukan Bawang Merah**

**Pupuk Dasar (sebelum tanam):**
- Pupuk kandang: 10–15 ton/ha
- SP-36: 150–200 kg/ha
- KCl: 100–150 kg/ha

**Pupuk Susulan:**
- Umur 2 minggu: Urea 100 kg/ha
- Umur 4 minggu: Urea 100 + KCl 100 kg/ha
- Umur 6 minggu: KCl 100 kg/ha

> ⚠️ *Jawaban ini dihasilkan secara offline. Untuk dosis spesifik, konsultasikan dengan penyuluh.*""",
    ),
    (
        ('panen', 'harvest', 'matang', 'siap panen', 'ciri panen'),
        """**Panduan Panen Bawang Merah**

**Ciri Siap Panen:**
- Umur 60–70 hari setelah tanam
- 60–70% daun sudah rebah alami
- Umbi keras, warna merah cerah
- Leher umbi mengecil

**Cara Panen:**
- Cabut di pagi hari saat tanah masih lembab
- Ikat dan jemur 5–7 hari di tempat teduh berangin
- Simpan di gudang berventilasi baik

> ⚠️ *Jawaban ini dihasilkan secara offline.*""",
    ),
    (
        ('tanam', 'bibit', 'benih', 'persiapan lahan', 'olah lahan'),
        """**Persiapan Tanam Bawang Merah**

**Persiapan Lahan:**
- Olah tanah sedalam 25–30 cm
- Buat bedengan lebar 100–120 cm, tinggi 25–30 cm
- pH ideal: 5.6–6.5 (tambahkan kapur jika terlalu asam)

**Pemilihan Bibit:**
- Pilih umbi sehat, tidak cacat
- Ukuran bibit: 5–10 gram/umbi
- Kebutuhan: 600–800 kg/ha

**Jarak Tanam:** 15×15 cm atau 20×20 cm

> ⚠️ *Jawaban ini dihasilkan secara offline.*""",
    ),
]


def _chat_fallback(question: str) -> str:
    """Jawaban berbasis kata kunci untuk pertanyaan umum bawang merah."""
    q = question.lower()
    for keywords, answer in _CHAT_RULES:
        if any(k in q for k in keywords):
            return answer
    return (
        "Maaf, AI sedang tidak tersedia saat ini.\n\n"
        "**Tips Umum Budidaya Bawang Merah:**\n"
        "- Tanam di musim kemarau untuk hasil terbaik\n"
        "- Pastikan drainase lahan baik\n"
        "- Periksa tanaman setiap hari dari hama & penyakit\n"
        "- Bawang merah siap panen usia 60\u201370 hari\n"
        "- pH tanah ideal 5.6\u20136.5\n\n"
        "> ⚠️ *Jawaban offline. Silakan coba lagi saat AI tersedia.*"
    )


# ─── Offline Fallback: /analyze-image ────────────────────────────────
ANALYZE_FALLBACK = """\
## ⚠️ AI Tidak Tersedia Saat Ini

AI tidak tersedia saat ini. Silakan coba lagi beberapa saat.

---

**Sementara itu, lakukan pemeriksaan manual:**

## 🔍 Panduan Identifikasi Visual

| Gejala yang Terlihat | Kemungkinan Masalah |
|---|---|
| Daun menguning & layu dari bawah | Layu Fusarium |
| Bercak coklat-ungu di daun | Bercak Ungu (Alternaria) |
| Bintik perak, daun mengkerut | Serangan Thrips |
| Daun berlubang, ada kotoran | Ulat Bawang |
| Umbi membusuk berbau | Busuk Umbi (Botrytis) |

## ✅ Langkah Awal yang Bisa Dilakukan

1. Cabut dan musnahkan tanaman yang terinfeksi parah
2. Perbaiki sistem drainase jika lahan terlalu lembab
3. Semprot fungisida/insektisida sesuai gejala
4. Konsultasikan dengan penyuluh pertanian setempat
"""


# ─── Offline Fallback: /estimate-harvest (rumus lokal) ──────────────────
def _estimate_harvest_fallback(data: HarvestInput) -> dict:
    """Hitung estimasi panen dengan rumus produktivitas lokal."""
    # Faktor produktivitas (kg/m²) berdasarkan kondisi tanaman
    faktor_map = {"baik": 1.1, "sedang": 0.9, "buruk": 0.6}
    faktor = faktor_map.get(data.kondisi_tanaman.lower(), 0.9)
    estimasi_kg = round(data.luas_lahan * faktor, 1)

    # Sisa hari menuju panen (rata-rata 65 hari)
    sisa_hari = max(0, 65 - data.umur_tanaman)
    if sisa_hari == 0:
        estimasi_waktu = "Sudah siap panen atau telah melewati waktu panen"
    else:
        estimasi_waktu = f"± {sisa_hari} hari lagi"

    # Tingkat risiko
    risiko_map = {
        "baik":   ("Rendah",  "Kondisi tanaman baik mendukung panen yang sukses"),
        "sedang": ("Sedang",  "Kondisi perlu ditingkatkan untuk hasil optimal"),
        "buruk":  ("Tinggi",  "Kondisi buruk meningkatkan risiko gagal panen"),
    }
    risiko, faktor_risiko = risiko_map.get(data.kondisi_tanaman.lower(), ("Sedang", ""))

    return {
        "estimasi_hari_panen": estimasi_waktu,
        "estimasi_hasil_kg":   estimasi_kg,
        "tingkat_risiko":      risiko,
        "faktor_risiko":       faktor_risiko,
        "rekomendasi": [
            "Pantau kondisi tanaman setiap hari",
            "Pastikan ketersediaan air yang cukup",
            "Lakukan pemupukan sesuai umur tanaman",
            "Waspadai serangan hama dan penyakit sejak dini",
        ],
        "catatan_penting": (
            f"Estimasi dihitung secara lokal (Mode Offline). "
            f"Produktivitas {faktor} kg/m² untuk kondisi {data.kondisi_tanaman}. "
            "Coba kembali saat AI tersedia untuk analisis lebih akurat."
        ),
    }


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
        return {"success": True, "fallback": False, "answer": response.text}

    except Exception:
        # Gemini gagal — gunakan jawaban berbasis kata kunci lokal
        return {
            "success": True,
            "fallback": True,
            "answer": _chat_fallback(data.question),
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
        return {"success": True, "fallback": False, "result": response.text}

    except PIL.UnidentifiedImageError:
        # File bukan gambar — kembalikan error biasa (bukan fallback)
        return {
            "success": False,
            "message": "File yang diunggah bukan gambar yang valid. Pastikan file berformat JPG atau PNG."
        }
    except Exception:
        # Gemini gagal — kembalikan panduan manual statis
        return {
            "success": True,
            "fallback": True,
            "result": ANALYZE_FALLBACK,
        }


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
            return {"success": True, "fallback": False, "status": "success", "data": result}
        except json.JSONDecodeError:
            pass

        # Fallback: ekstrak JSON dari teks menggunakan regex
        json_match = re.search(r'\{.*\}', text, re.DOTALL)
        if json_match:
            try:
                result = json.loads(json_match.group())
                return {"success": True, "fallback": False, "status": "success", "data": result}
            except json.JSONDecodeError:
                pass

        # Fallback terakhir: kembalikan teks mentah
        return {"success": True, "fallback": False, "status": "fallback", "raw": text}

    except Exception:
        # Gemini gagal — hitung dengan rumus lokal
        return {
            "success": True,
            "fallback": True,
            "status": "success",
            "data": _estimate_harvest_fallback(data),
        }