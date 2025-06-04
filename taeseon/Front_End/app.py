from flask import Flask, request, jsonify, send_from_directory
from flask_socketio import SocketIO, emit
from flask_cors import CORS
import os, json
from datetime import datetime, timedelta

app = Flask(__name__, static_folder='.')
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

KEY_DIR = "/root/sshkey"  # ✅ PEM 키 파일 디렉토리 경로

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

    user_id = data.get("userId", "anonymous")
    kst_time = datetime.utcnow() + timedelta(hours=9)
    timestamp = kst_time.strftime("%Y%m%d_%H%M%S")
    filename = f"{user_id}_{timestamp}_input_data.json"
    path = os.path.join(os.path.dirname(__file__), filename)

    try:
        with open(path, "w") as f:
            json.dump(data, f, indent=2)
        print(f"✅ 저장됨: {path}")
    except Exception as e:
        print(f"❌ 저장 실패 ({path}): {e}")

    return jsonify({"message": f"{filename} 저장 완료!"}), 200

@app.route("/final", methods=["POST"])
def save_final_input():
    data = request.get_json()
    print("📥 최종 입력값 (2단계):", data)

    input_files = [f for f in os.listdir('.') if f.endswith('_input_data.json')]
    input_files.sort(key=lambda x: os.path.getmtime(x), reverse=True)

    user_name = "anonymous"
    if input_files:
        try:
            with open(input_files[0], "r") as f:
                input_data = json.load(f)
                user_name = input_data.get("userId", "anonymous")
        except Exception as e:
            print(f"❌ user_name 추출 실패: {e}")

    if "userinput" in data:
        data["userinput"]["user_name"] = user_name

    kst_time = datetime.utcnow() + timedelta(hours=9)
    timestamp = kst_time.strftime("%Y%m%d_%H%M%S")
    filename = f"{user_name}_{timestamp}_final_data.json"
    path = os.path.join(os.path.dirname(__file__), filename)

    try:
        with open(path, "w") as f:
            json.dump(data, f, indent=2)
        print(f"✅ 최종 저장됨: {path}")
    except Exception as e:
        print(f"❌ 최종 저장 실패 ({path}): {e}")

    return jsonify({"message": f"{filename} 저장 완료!"}), 200

# ✅ 키 파일 리스트 반환 API
@app.route("/available-keys")
def list_keys():
    try:
        files = [f for f in os.listdir(KEY_DIR) if f.endswith(".pem")]
        return jsonify(files)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ✅ 키 파일 다운로드 API
@app.route("/download/<filename>")
def download_key(filename):
    if not filename.endswith(".pem"):
        return {"error": "Invalid file"}, 400
    return send_from_directory(KEY_DIR, filename, as_attachment=True)

if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=5000)
