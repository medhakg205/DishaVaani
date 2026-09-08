# standalone_server.py — Flask server (Render deployment) mirroring the Cloud Function
import json
import os
import tempfile

import firebase_admin
import requests
from deep_translator import GoogleTranslator
from firebase_admin import credentials, firestore
from flask import Flask, jsonify, request
from flask_cors import CORS
from google import genai
from dotenv import load_dotenv
load_dotenv()
from gtts import gTTS

cred_dict = json.loads(os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON"))
cred = credentials.Certificate(cred_dict)
firebase_admin.initialize_app(cred, options={"projectId": "dishavaani-db373"})

app = Flask(__name__)
CORS(app)

@app.route("/", methods=["GET"])
@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "healthy", "service": "dishavaani-audio"}), 200

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_KEY")
gemini_client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))


def personalize_script(base_script: str, interest_profile: dict) -> str:
    if not interest_profile:
        return base_script  # no profile provided, skip personalization

    top_interests = [
        interest for interest, score in sorted(
            interest_profile.items(), key=lambda item: item[1], reverse=True
        )[:2]
        if score > 0
    ]
    if not top_interests:
        return base_script
    prompt = (
        f"Rewrite this monument description to emphasize {', '.join(top_interests)}, "
        f"while keeping all these facts accurate: {base_script} "
        f"Keep it to 3-4 sentences, spoken narration style."
    )

    try:
        response = gemini_client.models.generate_content(
            model="gemini-3.6-flash",
            contents=prompt
        )
        if response.text and response.text.strip():
            return response.text.strip()
    except Exception as e:
        print(f"Personalization error: {e}")
    return base_script


def translate_text(text: str, source_lang: str, target_lang: str) -> str:
    if not text:
        return text
    if source_lang.lower().strip() == target_lang.lower().strip():
        return text

    # 1. First attempt: Use Gemini for fluent, natural regional translation
    try:
        prompt = (
            f"You are a professional audio guide narrator and translator. "
            f"Translate the following text from {source_lang} to language code '{target_lang}'. "
            f"Output ONLY the translated spoken narration without explanations, markdown, or quotation marks:\n\n"
            f"{text}"
        )
        response = gemini_client.models.generate_content(
            model="gemini-3.6-flash",
            contents=prompt
        )
        if response.text and response.text.strip():
            return response.text.strip()
    except Exception as ge:
        print(f"Gemini translation fallback: {ge}")

    # 2. Second attempt: GoogleTranslator with sanitized text
    try:
        clean_text = text.replace("’", "'").replace("“", '"').replace("”", '"')
        return GoogleTranslator(source=source_lang, target=target_lang).translate(clean_text)
    except Exception as te:
        print(f"GoogleTranslator fallback failed: {te}")

    # 3. If translation fails, return original text instead of crashing
    return text


def upload_audio_to_supabase(local_audio_path: str, storage_path: str) -> tuple[str, str | None]:
    """Uploads file to Supabase storage, trying candidate buckets (Audio, audio) with auto-fallback."""
    env_bucket = os.environ.get("SUPABASE_BUCKET_NAME")
    candidates = [env_bucket, "Audio", "audio"]
    buckets = [b for b in dict.fromkeys(candidates) if b]

    last_error = None
    with open(local_audio_path, "rb") as audio_file:
        file_bytes = audio_file.read()

    for bucket in buckets:
        upload_endpoint = f"{SUPABASE_URL}/storage/v1/object/{bucket}/{storage_path}"
        try:
            upload_response = requests.post(
                upload_endpoint,
                headers={
                    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
                    "Content-Type": "audio/mpeg",
                    "x-upsert": "true",
                },
                data=file_bytes,
                timeout=30,
            )
            if upload_response.status_code in (200, 201):
                public_url = f"{SUPABASE_URL}/storage/v1/object/public/{bucket}/{storage_path}"
                return public_url, None
            last_error = upload_response.text
        except Exception as e:
            last_error = str(e)

    return "", last_error


@app.route("/generate_regional_audio", methods=["POST"])
def generate_regional_audio():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Missing JSON body"}), 400

    poi_id = data.get("poiId")
    source_script = data.get("sourceScript")
    source_lang = data.get("sourceLang", "en")
    target_lang = data.get("targetLanguage")
    interest_profile = data.get("interestProfile")  # optional, may be None
    read_aloud = data.get("readAloud", False) or data.get("forceTts", False)

    if not poi_id or not source_script or not target_lang:
        return jsonify({"error": "poiId, sourceScript, and targetLanguage are required"}), 400

    db = firestore.client()
    doc_ref = db.collection("pois").document(poi_id)
    doc = doc_ref.get()

    if not doc.exists:
        return jsonify({"error": "POI not found"}), 404

    poi_data = doc.to_dict()
    existing_urls = poi_data.get("audioUrls", {})
    existing_read_aloud_urls = poi_data.get("readAloudUrls", {})
    existing_scripts = poi_data.get("scripts", {})

    # If read-aloud is requested and already generated/cached, return it immediately
    if read_aloud and not interest_profile and target_lang in existing_read_aloud_urls:
        return jsonify({
            "audioUrl": existing_read_aloud_urls[target_lang],
            "script": existing_scripts.get(target_lang, source_script),
        }), 200

    # Normal static fallback if read_aloud is NOT requested and not personalized
    if not read_aloud and not interest_profile and target_lang in existing_urls:
        return jsonify({
            "audioUrl": existing_urls[target_lang],
            "script": existing_scripts.get(target_lang, source_script),
        }), 200

    # Script processing:
    if not read_aloud and interest_profile:
        spoken_script = personalize_script(source_script, interest_profile)
        print(f"PERSONALIZED ({source_lang}): {spoken_script}")
    else:
        # Static script read-aloud: use existing translated script if available, or source_script
        spoken_script = existing_scripts.get(target_lang) or source_script

    if target_lang != source_lang and spoken_script == source_script:
        translated_text = translate_text(spoken_script, source_lang, target_lang)
    else:
        translated_text = spoken_script

    try:
        try:
            tts = gTTS(text=translated_text, lang=target_lang)
        except Exception:
            tts = gTTS(text=translated_text, lang=source_lang)

        with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp_file:
            tts.save(tmp_file.name)
            local_audio_path = tmp_file.name
    except Exception as e:
        return jsonify({"error": f"Text-to-speech failed: {str(e)}"}), 500

    if interest_profile and not read_aloud:
        top_interests = [
            interest for interest, score in sorted(
                interest_profile.items(), key=lambda item: item[1], reverse=True
            )[:2]
            if score > 0
        ]
        profile_tag = "_".join(sorted(top_interests)) if top_interests else "personalized"
        file_name = f"{poi_id}_{target_lang}_{profile_tag}.mp3"
    elif read_aloud:
        file_name = f"{poi_id}_{target_lang}_read_aloud.mp3"
    else:
        file_name = f"{poi_id}_{target_lang}.mp3"

    storage_path = f"tts_cached/{file_name}"

    try:
        public_audio_url, upload_err = upload_audio_to_supabase(local_audio_path, storage_path)
    finally:
        if os.path.exists(local_audio_path):
            os.remove(local_audio_path)

    if not public_audio_url:
        return jsonify({"error": f"Supabase upload failed: {upload_err}"}), 500

    # Cache in Firestore
    if read_aloud:
        doc_ref.update({
            f"readAloudUrls.{target_lang}": public_audio_url,
            f"scripts.{target_lang}": translated_text,
        })
    elif not interest_profile:
        doc_ref.update({
            f"audioUrls.{target_lang}": public_audio_url,
            f"scripts.{target_lang}": translated_text,
        })

    return jsonify({
        "audioUrl": public_audio_url,
        "script": translated_text,
    }), 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
