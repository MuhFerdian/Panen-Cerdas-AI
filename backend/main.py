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


# ─── Offline Fallback: /analyze-image (Database Lokal) ──────────────────
_DISEASE_DB = [
    {
        "keywords": ["menguning", "kuning", "layu", "fusarium"],
        "data": {
            "penyakit": "Layu Fusarium",
            "confidence": 85,
            "keparahan": "Sedang",
            "status": "Perlu Perhatian",
            "gejala": "Daun menguning, layu dari bagian bawah ke atas.",
            "penyebab": "Jamur Fusarium oxysporum yang menyerang akar dan umbi.",
            "solusi": [
                "Cabut dan musnahkan tanaman yang terserang",
                "Perbaiki drainase lahan",
                "Gunakan fungisida berbahan aktif mankozeb atau difenokonazol"
            ],
            "pencegahan": [
                "Gunakan bibit bebas penyakit",
                "Rotasi tanaman dengan tanaman bukan sefamili"
            ],
            "pupuk": "Gunakan pupuk organik cair, hindari pupuk N berlebih."
        }
    },
    {
        "keywords": ["bercak", "ungu", "alternaria"],
        "data": {
            "penyakit": "Bercak Ungu (Alternaria)",
            "confidence": 88,
            "keparahan": "Sedang",
            "status": "Perlu Perhatian",
            "gejala": "Terdapat bercak kecil melekuk berwarna putih hingga abu-abu, yang lama-kelamaan menjadi ungu dengan tepi kemerahan.",
            "penyebab": "Jamur Alternaria porri.",
            "solusi": [
                "Potong bagian daun yang terinfeksi",
                "Semprotkan fungisida sistemik (difenokonazol, azoksistrobin)"
            ],
            "pencegahan": [
                "Atur jarak tanam agar tidak terlalu rapat",
                "Jaga kebersihan lahan"
            ],
            "pupuk": "Gunakan pupuk kalium (K) untuk memperkuat jaringan daun."
        }
    },
    {
        "keywords": ["keriting", "mengeriting", "bintik", "perak", "thrips"],
        "data": {
            "penyakit": "Serangan Thrips",
            "confidence": 90,
            "keparahan": "Berat",
            "status": "Perlu Penanganan Segera",
            "gejala": "Daun mengeriting, melintir, dan terdapat bintik-bintik keperakan akibat isapan hama.",
            "penyebab": "Hama Thrips tabaci.",
            "solusi": [
                "Gunakan perangkap lekat kuning/biru",
                "Semprot insektisida berbahan aktif abamektin atau imidakloprid"
            ],
            "pencegahan": [
                "Lakukan penyiraman dengan cara disemprot kuat (sprinkler) untuk merontokkan hama",
                "Jaga kebersihan gulma"
            ],
            "pupuk": "Berikan pupuk daun bernutrisi seimbang untuk memulihkan daun."
        }
    },
    {
        "keywords": ["lubang", "berlubang", "ulat"],
        "data": {
            "penyakit": "Ulat Bawang",
            "confidence": 80,
            "keparahan": "Sedang",
            "status": "Perlu Perhatian",
            "gejala": "Daun berlubang, kadang terdapat kotoran ulat di dalam rongga daun, daun terpotong.",
            "penyebab": "Hama ulat Spodoptera exigua.",
            "solusi": [
                "Kumpulkan dan musnahkan kelompok telur ulat secara manual",
                "Gunakan insektisida biologi (Bacillus thuringiensis) atau kimia (klorantraniliprol)"
            ],
            "pencegahan": [
                "Gunakan kelambu (screen net)",
                "Pasang perangkap feromon"
            ],
            "pupuk": "Pemupukan standar, fokus pada pengendalian hama terlebih dahulu."
        }
    },
    {
        "keywords": ["busuk", "umbi", "botrytis"],
        "data": {
            "penyakit": "Busuk Umbi (Botrytis)",
            "confidence": 92,
            "keparahan": "Berat",
            "status": "Perlu Penanganan Segera",
            "gejala": "Leher umbi melunak, membusuk, dan sering ditutupi miselium jamur abu-abu.",
            "penyebab": "Jamur Botrytis allii, sering terjadi di lahan basah atau saat penyimpanan.",
            "solusi": [
                "Segera singkirkan umbi yang terinfeksi",
                "Perbaiki sistem drainase air",
                "Gunakan fungisida (klorotalonil)"
            ],
            "pencegahan": [
                "Keringkan umbi dengan baik setelah panen",
                "Pastikan gudang penyimpanan kering dan berventilasi"
            ],
            "pupuk": "Hindari pupuk Nitrogen tinggi menjelang panen."
        }
    },
    {
        "keywords": ["antraknosa", "mati bujang", "patah"],
        "data": {
            "penyakit": "Antraknosa (Mati Bujang)",
            "confidence": 85,
            "keparahan": "Berat",
            "status": "Perlu Penanganan Segera",
            "gejala": "Bercak putih pada daun, kemudian daun patah (terkulai) secara serentak.",
            "penyebab": "Jamur Colletotrichum gloeosporioides.",
            "solusi": [
                "Hentikan penyiraman sementara jika tanah sangat basah",
                "Semprot fungisida berbahan aktif propineb atau tebukonazol"
            ],
            "pencegahan": [
                "Gunakan jarak tanam yang lebih lebar",
                "Gunakan mulsa plastik"
            ],
            "pupuk": "Tingkatkan unsur K dan Ca untuk mengeraskan jaringan tanaman."
        }
    }
]

def _analyze_image_fallback(filename: str) -> str:
    """Mendiagnosis penyakit bawang merah dari keywords pada filename saat mode offline."""
    import json
    
    filename_lower = filename.lower() if filename else ""
    for entry in _DISEASE_DB:
        if any(k in filename_lower for k in entry["keywords"]):
            return json.dumps(entry["data"])
    
    # Default jika tidak ada keyword yang cocok
    return json.dumps({
        "penyakit": "Penyakit Tidak Dikenali (Database Lokal)",
        "confidence": 50,
        "keparahan": "Sedang",
        "status": "Perlu Perhatian",
        "gejala": "Tidak dapat mendeteksi gejala secara spesifik dari nama file. Panduan: Periksa daun menguning (Fusarium), bercak ungu (Alternaria), daun mengeriting (Thrips), berlubang (Ulat), atau busuk umbi.",
        "penyebab": "AI sedang offline. Sistem mendeteksi melalui metadata file namun tidak ada kata kunci yang cocok dengan database lokal.",
        "solusi": [
            "Periksa tanaman secara manual menggunakan panduan",
            "Konsultasikan dengan penyuluh pertanian"
        ],
        "pencegahan": [
            "Jaga kebersihan lahan",
            "Pastikan drainase baik"
        ],
        "pupuk": "Gunakan pupuk berimbang sesuai umur tanaman."
    })


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

        Analisis gambar tanaman bawang merah berikut secara menyeluruh.
        Berikan laporan HANYA dalam format JSON berikut tanpa tambahan teks atau markdown lain:
        {
            "penyakit": "Nama Penyakit atau Masalah",
            "confidence": angka_0_sampai_100,
            "keparahan": "Ringan / Sedang / Berat",
            "status": "Aman / Perlu Perhatian / Perlu Penanganan Segera",
            "gejala": "Deskripsi gejala visual yang terlihat pada tanaman dalam gambar.",
            "penyebab": "Jelaskan penyebab penyakit atau masalah tersebut (jamur, bakteri, hama, kekurangan nutrisi, dll).",
            "solusi": [
                "Langkah penanganan 1",
                "Langkah penanganan 2",
                "Langkah penanganan 3"
            ],
            "pencegahan": [
                "Tips pencegahan 1",
                "Tips pencegahan 2"
            ],
            "pupuk": "Sebutkan rekomendasi pupuk, produk, atau bahan aktif."
        }
        Jika gambar tidak menampilkan tanaman bawang merah atau gambar tidak jelas, tetap gunakan format JSON tersebut, isi "penyakit" dengan "Bukan Tanaman / Gambar Tidak Jelas", "confidence" dengan 0, "status" dengan "Aman", dan jelaskan pada "gejala" atau "penyebab".
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
        # Gemini gagal — gunakan database lokal berdasarkan nama file
        fallback_json = _analyze_image_fallback(file.filename)
        return {
            "success": True,
            "fallback": True,
            "result": fallback_json,
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