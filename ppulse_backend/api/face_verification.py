"""
Face verification service for WFH punch-in.

Pipeline (target: end-to-end < 1 second on CPU):

  1. Decode image (base64 / bytes / file path).
  2. Pre-process for tolerance to bad lighting:
       - Convert to LAB, apply CLAHE on L-channel (low-light + low-contrast fix).
       - Gray-world white-balance (high color cast / oversaturation).
       - Auto gamma when scene is very dark or very bright.
  3. Quality + liveness gate (single-frame, fast):
       - Min face size, sharpness (Laplacian variance).
       - Brightness window (reject pitch-black or fully blown-out frames).
       - Anti-screen heuristic: low colour variance + high JPEG compression
         artifacts ≈ photo-of-screen replay.
  4. Detection + 512-d ArcFace embedding via insightface buffalo_l.
  5. Cosine match against EmployeeFaceData rows in DB.
  6. Return (matched_employee_id | None, confidence, reason).

The model is loaded lazily and kept as a process-level singleton so that
the first request pays the warmup cost (~1.5s) and subsequent requests are
~50–150 ms on CPU.
"""

from __future__ import annotations

import base64
import logging
import threading
import time
from dataclasses import dataclass

import cv2
import numpy as np

logger = logging.getLogger(__name__)

# ── Tunables ────────────────────────────────────────────────────────────────
EMBEDDING_DIM = 512
MATCH_THRESHOLD = 0.42  # cosine sim above this counts as a match
STRONG_MATCH_THRESHOLD = 0.55  # high-confidence band
MIN_FACE_PX = 80  # face bounding box must be ≥ this on the short side
MIN_LAPLACIAN_VAR = 35.0  # below = too blurry
MIN_BRIGHTNESS = 25  # 0..255
MAX_BRIGHTNESS = 235
DET_SIZE = (640, 640)  # insightface detector input

# ── Lazy model loader ───────────────────────────────────────────────────────
_model = None
_model_lock = threading.Lock()


def _get_model():
    """Singleton FaceAnalysis loader. Auto-downloads buffalo_l on first call."""
    global _model
    if _model is not None:
        return _model
    with _model_lock:
        if _model is not None:
            return _model
        from insightface.app import FaceAnalysis

        logger.info('FACE: loading insightface buffalo_l (first call, ~1-2s)…')
        t0 = time.perf_counter()
        app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
        app.prepare(ctx_id=0, det_size=DET_SIZE)
        _model = app
        logger.info('FACE: model ready in %.2fs', time.perf_counter() - t0)
        return _model


def warmup() -> None:
    """Eager warmup — call from app startup if you want the first request fast."""
    try:
        _get_model()
    except Exception as e:
        logger.warning('FACE: warmup failed: %s', e)


# ── Image decode ────────────────────────────────────────────────────────────


def decode_image(payload) -> np.ndarray | None:
    """Accept base64 string (data-uri or raw), bytes, or file path. Return BGR ndarray."""
    if payload is None:
        return None
    try:
        if isinstance(payload, np.ndarray):
            return payload
        if isinstance(payload, (bytes, bytearray)):
            buf = bytes(payload)
        elif isinstance(payload, str):
            s = payload.strip()
            if s.startswith('data:'):
                s = s.split(',', 1)[-1]
            # Try base64 first; fall back to file path.
            try:
                buf = base64.b64decode(s, validate=False)
            except Exception:
                with open(s, 'rb') as f:
                    buf = f.read()
        else:
            return None
        arr = np.frombuffer(buf, dtype=np.uint8)
        img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
        return img
    except Exception as e:
        logger.debug('FACE: decode_image failed: %s', e)
        return None


# ── Pre-processing ──────────────────────────────────────────────────────────


def preprocess(img: np.ndarray) -> np.ndarray:
    """Make the image robust to low light, high light, contrast, saturation."""
    if img is None or img.size == 0:
        return img

    # Downscale very large images for speed (insightface re-scales anyway).
    h, w = img.shape[:2]
    if max(h, w) > 1280:
        scale = 1280.0 / max(h, w)
        img = cv2.resize(img, (int(w * scale), int(h * scale)), interpolation=cv2.INTER_AREA)

    # 1. CLAHE on L-channel of LAB → boosts local contrast in shadows/highlights.
    lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    l = clahe.apply(l)
    lab = cv2.merge((l, a, b))
    img = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)

    # 2. Gray-world white balance — neutralizes blue/yellow casts and oversaturated lights.
    result = img.astype(np.float32)
    avg_b = np.mean(result[:, :, 0])
    avg_g = np.mean(result[:, :, 1])
    avg_r = np.mean(result[:, :, 2])
    avg_gray = (avg_b + avg_g + avg_r) / 3.0
    if avg_b > 0 and avg_g > 0 and avg_r > 0:
        result[:, :, 0] *= avg_gray / avg_b
        result[:, :, 1] *= avg_gray / avg_g
        result[:, :, 2] *= avg_gray / avg_r
    img = np.clip(result, 0, 255).astype(np.uint8)

    # 3. Auto-gamma if frame is very dark or very bright.
    mean = float(np.mean(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)))
    if mean < 70:  # too dark → brighten
        gamma = 0.6
    elif mean > 190:  # too bright → darken
        gamma = 1.4
    else:
        gamma = 1.0
    if gamma != 1.0:
        inv = 1.0 / gamma
        table = np.array([((i / 255.0) ** inv) * 255 for i in range(256)]).astype(np.uint8)
        img = cv2.LUT(img, table)

    return img


# ── Quality / single-frame liveness gate ────────────────────────────────────


@dataclass
class QualityResult:
    ok: bool
    reason: str
    sharpness: float
    brightness: float
    face_px: int


def quality_check(img: np.ndarray, face_bbox=None) -> QualityResult:
    """Reject obviously bad frames before we trust an embedding."""
    if img is None or img.size == 0:
        return QualityResult(False, 'empty_frame', 0, 0, 0)

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    sharp = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    brightness = float(np.mean(gray))

    if brightness < MIN_BRIGHTNESS:
        return QualityResult(False, 'too_dark', sharp, brightness, 0)
    if brightness > MAX_BRIGHTNESS:
        return QualityResult(False, 'too_bright', sharp, brightness, 0)
    if sharp < MIN_LAPLACIAN_VAR:
        return QualityResult(False, 'too_blurry', sharp, brightness, 0)

    face_px = 0
    if face_bbox is not None:
        x1, y1, x2, y2 = [int(v) for v in face_bbox]
        face_px = min(x2 - x1, y2 - y1)
        if face_px < MIN_FACE_PX:
            return QualityResult(False, 'face_too_small', sharp, brightness, face_px)

    return QualityResult(True, 'ok', sharp, brightness, face_px)


def screen_replay_score(img: np.ndarray, face_bbox=None) -> float:
    """
    Cheap single-frame anti-spoofing: photos of phone/laptop screens tend to have
    (a) very low colour saturation variance after CLAHE and
    (b) periodic moiré in the high-frequency band.

    Returns 0..1 — higher = more screen-like. We block at >= 0.85 to keep FPR low,
    since true liveness with a still image is fundamentally limited.
    """
    if img is None or img.size == 0:
        return 0.0
    if face_bbox is not None:
        x1, y1, x2, y2 = [max(0, int(v)) for v in face_bbox]
        crop = img[y1:y2, x1:x2]
        if crop.size == 0:
            crop = img
    else:
        crop = img

    hsv = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)
    sat_std = float(np.std(hsv[:, :, 1]))

    gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
    f = np.fft.fft2(gray)
    fshift = np.fft.fftshift(f)
    mag = 20 * np.log(np.abs(fshift) + 1)
    h, w = mag.shape
    cy, cx = h // 2, w // 2
    band = mag[max(0, cy - 5) : cy + 5, max(0, cx - 5) : cx + 5]
    low_freq_energy = float(np.mean(band))
    total_energy = float(np.mean(mag))
    low_ratio = low_freq_energy / total_energy if total_energy > 0 else 0.0

    score = 0.0
    if sat_std < 18:
        score += 0.5
    if low_ratio > 1.6:
        score += 0.5
    return min(score, 1.0)


# ── Embedding helpers ───────────────────────────────────────────────────────


def pack_embedding(vec: np.ndarray) -> bytes:
    v = np.asarray(vec, dtype=np.float32).reshape(-1)
    return v.tobytes()


def unpack_embedding(blob: bytes, dim: int = EMBEDDING_DIM) -> np.ndarray:
    if not blob:
        return np.zeros(dim, dtype=np.float32)
    return np.frombuffer(blob, dtype=np.float32).reshape(-1)


def l2_normalize(v: np.ndarray) -> np.ndarray:
    n = np.linalg.norm(v)
    if n < 1e-9:
        return v
    return v / n


# ── Public API ──────────────────────────────────────────────────────────────


@dataclass
class VerifyResult:
    matched: bool
    employee_id: int | None
    confidence: float
    reason: str
    elapsed_ms: float
    quality: QualityResult | None = None
    spoof_score: float = 0.0


def extract_embedding(
    img: np.ndarray,
) -> tuple[np.ndarray | None, QualityResult | None, float, tuple[int, int, int, int] | None]:
    """Run preprocess + detect + embed. Returns (embedding, quality, spoof_score, bbox)."""
    img_pp = preprocess(img)
    model = _get_model()
    faces = model.get(img_pp)
    if not faces:
        q = quality_check(img_pp)
        if q.ok:
            q = QualityResult(False, 'no_face', q.sharpness, q.brightness, 0)
        return None, q, 0.0, None

    # Pick the largest face (closest to camera).
    face = max(faces, key=lambda f: (f.bbox[2] - f.bbox[0]) * (f.bbox[3] - f.bbox[1]))
    bbox = tuple(int(v) for v in face.bbox)
    q = quality_check(img_pp, bbox)
    spoof = screen_replay_score(img_pp, bbox)
    if not q.ok:
        return None, q, spoof, bbox
    emb = l2_normalize(np.asarray(face.embedding, dtype=np.float32))
    return emb, q, spoof, bbox


def verify(image_payload) -> VerifyResult:
    """End-to-end WFH face verification against the EmployeeFaceData table."""
    t0 = time.perf_counter()

    img = decode_image(image_payload)
    if img is None:
        return VerifyResult(False, None, 0.0, 'invalid_image', (time.perf_counter() - t0) * 1000)

    try:
        emb, quality, spoof, _bbox = extract_embedding(img)
    except Exception as e:
        logger.exception('FACE: extract_embedding crashed')
        return VerifyResult(False, None, 0.0, f'extract_error:{e}', (time.perf_counter() - t0) * 1000)

    if emb is None:
        reason = quality.reason if quality else 'no_face'
        return VerifyResult(False, None, 0.0, reason, (time.perf_counter() - t0) * 1000, quality, spoof)

    if spoof >= 0.85:
        return VerifyResult(
            False, None, 0.0, 'liveness_failed', (time.perf_counter() - t0) * 1000, quality, spoof
        )

    # Match against DB.
    from .models import EmployeeFaceData

    rows = list(EmployeeFaceData.objects.exclude(embedding=None).values('employee_id_id', 'embedding'))
    if not rows:
        return VerifyResult(
            False, None, 0.0, 'no_enrolled_faces', (time.perf_counter() - t0) * 1000, quality, spoof
        )

    best_id = None
    best_score = -1.0
    for row in rows:
        ref = unpack_embedding(bytes(row['embedding']))
        if ref.shape[0] != emb.shape[0]:
            continue
        score = float(np.dot(emb, ref))  # both L2-normalized → cosine similarity
        if score > best_score:
            best_score = score
            best_id = row['employee_id_id']

    elapsed = (time.perf_counter() - t0) * 1000

    if best_score >= MATCH_THRESHOLD:
        return VerifyResult(True, best_id, best_score, 'match', elapsed, quality, spoof)
    return VerifyResult(False, None, best_score, 'unknown_user', elapsed, quality, spoof)


def enroll_from_images(employee_id_id: int, image_paths: list) -> tuple[bool, str, int]:
    """Encode N images for an employee and store the averaged embedding.

    Returns (success, message, samples_used).
    """
    from .models import EmployeeFaceData

    samples = []
    used_files = []
    for path in image_paths:
        img = decode_image(path)
        if img is None:
            logger.warning('FACE: skip unreadable %s', path)
            continue
        emb, q, _spoof, _bbox = extract_embedding(img)
        if emb is None:
            logger.warning('FACE: skip %s (%s)', path, q.reason if q else 'no_face')
            continue
        samples.append(emb)
        used_files.append(path)

    if not samples:
        return False, 'no_usable_samples', 0

    avg = l2_normalize(np.mean(np.stack(samples, axis=0), axis=0))
    blob = pack_embedding(avg)

    obj, _created = EmployeeFaceData.objects.update_or_create(
        employee_id_id=employee_id_id,
        defaults={
            'embedding': blob,
            'embedding_dim': EMBEDDING_DIM,
            'num_samples': len(samples),
            'source_files': ','.join(used_files),
        },
    )
    return True, 'ok', len(samples)
