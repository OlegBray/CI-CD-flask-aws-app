from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import pymysql
import boto3
import json
import get_parameters


app = Flask(__name__)
CORS(app)

# קריאה ל-SSM Parameter Store
def get_parameter(name):
    ssm = boto3.client("ssm", region_name="il-central-1")
    param = ssm.get_parameter(Name=name, WithDecryption=True)
    return param['Parameter']['Value']

# שליפת פרטי ההתחברות
db_host = get_parameter("/imtech/oleg/endpoint")
# print(db_host)
db_user = get_parameters.get_secret()["username"]
# print(db_user)
db_pass = get_parameters.get_secret()["password"]
# print(db_pass)
db_name = "oleg"

# התחברות למסד
def get_db_connection():
    return pymysql.connect(
        host=db_host,
        user=db_user,
        password=db_pass,
        database=db_name,
        cursorclass=pymysql.cursors.DictCursor
    )

@app.route("/")
def serve_index():
    return send_from_directory("../frontend", "index.html")

@app.route("/add-name", methods=["POST"])
def add_name():
    data = request.get_json()
    name = data.get("name")

    if not name:
        return jsonify({"error": "Name is required"}), 400

    try:
        conn = get_db_connection()
        with conn:
            with conn.cursor() as cursor:
                cursor.execute("INSERT INTO params (`Name`) VALUES (%s)", (name,))
                conn.commit()
        return jsonify({"message": f"Added '{name}' to the database!"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
@app.route("/main.js")
def serve_js():
    return send_from_directory("../frontend", "main.js")

    

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=1234)