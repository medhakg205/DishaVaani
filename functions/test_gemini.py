import os
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))

def personalize_script(base_script: str, interest_profile: dict) -> str:
    top_interests = sorted(interest_profile, key=interest_profile.get, reverse=True)[:2]
    prompt = (
        f"Rewrite this monument description to emphasize {', '.join(top_interests)}, "
        f"while keeping all these facts accurate: {base_script} "
        f"Keep it to 3-4 sentences, spoken narration style."
    )
    response = client.models.generate_content(model="gemini-3.6-flash", contents=prompt)
    return response.text

base_script = "This gate was built in the 13th century as the entrance to a fortified complex. It features intricate stone carvings and was later used as a military checkpoint during regional conflicts."

profiles = {
    "History buff": {"history": 0.9, "architecture": 0.2, "military": 0.1},
    "Architecture lover": {"architecture": 0.9, "history": 0.2, "military": 0.0},
    "Military history fan": {"military": 0.9, "history": 0.4, "architecture": 0.1},
}

for label, profile in profiles.items():
    print(f"\n--- {label} ---")
    print(personalize_script(base_script, profile))