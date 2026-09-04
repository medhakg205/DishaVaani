import os
import tempfile

import firebase_admin
import requests
from deep_translator import GoogleTranslator
from firebase_admin import firestore
from firebase_functions import https_fn, options
from gtts import gTTS
import json
import mimetypes

import google.generativeai as genai

firebase_admin.initialize_app(options={'projectId': 'dishavaani-db373'})

SUPABASE_URL =  os.environ.get("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_KEY")
BUCKET_NAME = "audio"  # change if your Supabase bucket has a different name


@https_fn.on_request()
def generate_regional_audio(req: https_fn.Request) -> https_fn.Response:
    # --- 1. Read and validate the incoming request ---
    data = req.get_json(silent=True)
    if not data:
        return https_fn.Response("Missing JSON body", status=400)

    poi_id = data.get("poiId")
    source_script = data.get("sourceScript")
    source_lang = data.get("sourceLang", "en")
    target_lang = data.get("targetLanguage")

    if not poi_id or not source_script or not target_lang:
        return https_fn.Response(
            "poiId, sourceScript, and targetLanguage are required", status=400
        )

    db = firestore.client()
    doc_ref = db.collection("pois").document(poi_id)
    doc = doc_ref.get()

    if not doc.exists:
        return https_fn.Response("POI not found", status=404)

    poi_data = doc.to_dict()

    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        return https_fn.Response("Server misconfigured: missing Supabase credentials", status=500)

    # --- 2. Check the cache first — don't regenerate if it already exists ---
    existing_urls = poi_data.get("audioUrls", {})
    if target_lang in existing_urls:
        return https_fn.Response(
            {"audioUrl": existing_urls[target_lang]}, status=200
        )

    # --- 3. Translate the text ---
    try:
        translated_text = GoogleTranslator(
            source=source_lang, target=target_lang
        ).translate(source_script)
    except Exception as e:
        return https_fn.Response(f"Translation failed: {str(e)}", status=500)

    # --- 4. Convert translated text to speech ---
    try:
        tts = gTTS(text=translated_text, lang=target_lang)
        with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp_file:
            tts.save(tmp_file.name)
            local_audio_path = tmp_file.name
    except Exception as e:
        return https_fn.Response(f"Text-to-speech failed: {str(e)}", status=500)

    # --- 5. Upload the generated MP3 to Supabase Storage ---
    file_name = f"{poi_id}_{target_lang}.mp3"
    storage_path = f"tts_cached/{file_name}"

    supabase_url = SUPABASE_URL
    supabase_key = SUPABASE_SERVICE_KEY

    upload_endpoint = (
        f"{supabase_url}/storage/v1/object/{BUCKET_NAME}/{storage_path}"
    )

    with open(local_audio_path, "rb") as audio_file:
        upload_response = requests.post(
            upload_endpoint,
            headers={
                "Authorization": f"Bearer {supabase_key}",
                "Content-Type": "audio/mpeg",
                "x-upsert": "true",
            },
            data=audio_file.read(),
        )

    os.remove(local_audio_path)

    if upload_response.status_code not in (200, 201):
        return https_fn.Response(
            f"Supabase upload failed: {upload_response.text}", status=500
        )

    public_audio_url = (
        f"{supabase_url}/storage/v1/object/public/{BUCKET_NAME}/{storage_path}"
    )

    # --- 6. Update Firestore, adding the new language without wiping others ---
    doc_ref.update(
        {
            f"audioUrls.{target_lang}": public_audio_url,
            f"scripts.{target_lang}": translated_text,
        }
    )

    # --- 7. Return the URL to the app ---
    return https_fn.Response({"audioUrl": public_audio_url}, status=200)


GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")


@https_fn.on_request()
def parse_itinerary(req: https_fn.Request) -> https_fn.Response:
    if not GEMINI_API_KEY:
        return https_fn.Response("Server misconfigured: missing Gemini API key", status=500)

    uploaded_file = req.files.get("file")
    if not uploaded_file:
        return https_fn.Response("Missing uploaded file", status=400)

    file_bytes = uploaded_file.read()
    mime_type = uploaded_file.mimetype or mimetypes.guess_type(uploaded_file.filename)[0]

    if not mime_type:
        return https_fn.Response("Could not determine file type", status=400)

    genai.configure(api_key=GEMINI_API_KEY)
    model = genai.GenerativeModel("gemini-1.5-flash")

    prompt = (
        "Extract every planned visit from this travel itinerary. "
        "Return ONLY a JSON array, no other text, no markdown formatting. "
        "Each item must have exactly these fields: "
        "\"placeName\" (string), \"date\" (YYYY-MM-DD), "
        "\"startTime\" (HH:mm, 24-hour), \"endTime\" (HH:mm, 24-hour). "
        "If a specific time isn't given, make a reasonable estimate based on context. "
        "If a date isn't given, use today's date."
    )

    try:
        response = model.generate_content([
            prompt,
            {"mime_type": mime_type, "data": file_bytes},
        ])
    except Exception as e:
        return https_fn.Response(f"Gemini request failed: {str(e)}", status=500)

    raw_text = response.text.strip()

    # Gemini sometimes wraps JSON in markdown code fences despite instructions —
    # strip those if present before parsing.
    if raw_text.startswith("```"):
        raw_text = raw_text.strip("`")
        if raw_text.startswith("json"):
            raw_text = raw_text[4:].strip()

    try:
        stops = json.loads(raw_text)
    except Exception:
        return https_fn.Response(
            f"Could not parse Gemini's response as JSON: {raw_text[:200]}", status=500
        )

    return https_fn.Response(json.dumps({"stops": stops}), status=200, content_type="application/json")