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
        cur.execute('INSERT INTO user_data (data) VALUES (%s)',_
