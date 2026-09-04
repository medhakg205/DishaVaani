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
        return response.text
    except Exception:
        return base_script  # if Gemini fails, fall back to the original script
BUCKET_NAME = "audio"  # matches main.py — both now point to the same Supabase bucket

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


    if not poi_id or not source_script or not target_lang:
        return jsonify({"error": "poiId, sourceScript, and targetLanguage are required"}), 400

    db = firestore.client()
    doc_ref = db.collection("pois").document(poi_id)
    doc = doc_ref.get()

    if not doc.exists:
        return jsonify({"error": "POI not found"}), 404

    poi_data = doc.to_dict()
    existing_urls = poi_data.get("audioUrls", {})
    if target_lang in existing_urls:
        return jsonify({"audioUrl": existing_urls[target_lang]}), 200

    try:
        personalized_script = personalize_script(source_script, interest_profile)
        print(f"PERSONALIZED (English): {personalized_script}")
        translated_text = GoogleTranslator(source=source_lang, target=target_lang).translate(personalized_script)
    except Exception as e:
        return jsonify({"error": f"Translation failed: {str(e)}"}), 500

    try:
        tts = gTTS(text=translated_text, lang=target_lang)
        with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp_file:
            tts.save(tmp_file.name)
            local_audio_path = tmp_file.name
    except Exception as e:
        return jsonify({"error": f"Text-to-speech failed: {str(e)}"}), 500

    file_name = f"{poi_id}_{target_lang}.mp3"
    storage_path = f"tts_cached/{file_name}"
    upload_endpoint = f"{SUPABASE_URL}/storage/v1/object/{BUCKET_NAME}/{storage_path}"

    try:
        with open(local_audio_path, "rb") as audio_file:
            upload_response = requests.post(
                upload_endpoint,
                headers={
                    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
                    "Content-Type": "audio/mpeg",
                    "x-upsert": "true",
                },
                data=audio_file.read(),
                timeout=30,  # BUG FIX: no timeout previously
            )
    finally:
        os.remove(local_audio_path)  # BUG FIX: previously only removed on success path

    if upload_response.status_code not in (200, 201):
        return jsonify({"error": f"Supabase upload failed: {upload_response.text}"}), 500

    public_audio_url = f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET_NAME}/{storage_path}"

    doc_ref.update({
        f"audioUrls.{target_lang}": public_audio_url,
        f"scripts.{target_lang}": translated_text,
    })

    return jsonify({"audioUrl": public_audio_url}), 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)

