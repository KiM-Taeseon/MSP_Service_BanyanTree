from flask import Flask, request, jsonify, send_from_directory
import json
import os
from datetime import datetime, timedelta

app = Flask(__name__, static_folder='.')  # 현재 디렉토리에서 정적 파일 서빙

@app.route("/")
def index():
    return send_from_directory('.', "index.nginx-debian.html")

@app.route("/<path:filename>")
def static_files(filename):
    return send_from_directory('.', filename)

@app.route("/save", methods=["POST"])
def save_input():
    data = request.get_json()
    print("📥 입력값:", data)

    user_id = data.get("id", "anonymous")  # ID 없으면 기본 anonymous

    # ✅ 한국시간(KST = UTC + 9)
    kst_time = datetime.utcnow() + timedelta(hours=9)
    timestamp = kst_time.strftime("%Y%m%d_%H%M%S")

    filename = f"{user_id}_{timestamp}_input_data.json"
    save_path = os.path.join(os.path.dirname(__file__), filename)

    with open(save_path, "w") as f:
        json.dump(data, f, indent=2)

    print(f"✅ 저장됨: {filename}")
    return jsonify({"message": f"{filename} 저장 완료!"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

