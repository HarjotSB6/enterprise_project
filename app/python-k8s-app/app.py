from flask import Flask, render_template, request, redirect, url_for, flash
import psycopg2
import boto3
import os

app = Flask(__name__)
app.secret_key = 'your-secret-key'  # for flash messages

# DB connection setup - replace with your actual RDS credentials or use env vars
DB_HOST = os.getenv('DB_HOST', 'your-rds-endpoint')
DB_NAME = os.getenv('DB_NAME', 'appdb')
DB_USER = os.getenv('DB_USER', 'appadmin')
DB_PASS = os.getenv('DB_PASS', 'AppPass123!')
DB_PORT = 5432

# AWS S3 setup
S3_BUCKET = os.getenv('S3_BUCKET', 'your-s3-bucket-name')
S3_REGION = os.getenv('S3_REGION', 'us-east-1')

s3_client = boto3.client('s3', region_name=S3_REGION)

def get_db_connection():
    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        port=DB_PORT
    )
    return conn

def create_user_data_table():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS user_data (
            id SERIAL PRIMARY KEY,
            data TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)
    conn.commit()
    cur.close()
    conn.close()

create_user_data_table()  # Call it once at startup

@app.route('/')
def index():
    return redirect(url_for('input_tab'))

@app.route('/input', methods=['GET', 'POST'])
def input_tab():
    if request.method == 'POST':
        user_input = request.form.get('user_input')
        if not user_input:
            flash("Please enter some data.", "error")
            return redirect(url_for('input_tab'))

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('INSERT INTO user_data (data) VALUES (%s)', (user_input,))
        conn.commit()
        cur.close()
        conn.close()
        flash("Data saved successfully!", "success")
        return redirect(url_for('input_tab'))

    return render_template('input.html')

@app.route('/output', methods=['GET', 'POST'])
def output_tab():
    if request.method == 'POST':
        # Handle file upload
        if 'file' not in request.files:
            flash("No file part", "error")
            return redirect(url_for('output_tab'))

        file = request.files['file']
        if file.filename == '':
            flash("No selected file", "error")
            return redirect(url_for('output_tab'))

        try:
            s3_client.upload_fileobj(file, S3_BUCKET, file.filename)
            flash(f"File {file.filename} uploaded to S3.", "success")
            # Here you can trigger notification logic (email, etc.)
        except Exception as e:
            flash(f"Failed to upload file: {str(e)}", "error")

        return redirect(url_for('output_tab'))

    # Fetch stored data from DB
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT id, data FROM user_data ORDER BY id DESC')
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('output.html', rows=rows)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
