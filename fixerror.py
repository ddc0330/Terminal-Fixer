#!/usr/bin/env python3
import os
import sqlite3
import google.generativeai as genai
from dotenv import load_dotenv

# ============ Config ============

DB_PATH = "./fixerror.db"
LOG_PATH = "./logs/last_error.log"

# ============ Setup ============

load_dotenv()
API_KEY = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=API_KEY)

# ============ Database ============

def init_db():
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute('''
            CREATE TABLE IF NOT EXISTS error_solutions (
                error TEXT PRIMARY KEY,
                solution TEXT
            )
        ''')

# ============ Read Last Error ============

def read_last_error():
    if not os.path.exists(LOG_PATH):
        print("No error log found.")
        return None
    with open(LOG_PATH, "r") as f:
        return f.read()

# ============ Search Local DB ============

def search_solution(error_msg):
    with sqlite3.connect(DB_PATH) as conn:
        row = conn.execute("SELECT solution FROM error_solutions WHERE error=?", (error_msg,)).fetchone()
        return row[0] if row else None

# ============ Ask Gemini ============

def ask_gemini(error_msg):
    model = genai.GenerativeModel('models/gemini-1.5-flash')
    response = model.generate_content(f"Please help me resolve this Linux error:\n{error_msg}")
    return response.text

# ============ Save Solution ============

def save_solution(error_msg, solution):
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute("INSERT OR REPLACE INTO error_solutions (error, solution) VALUES (?,?)", (error_msg, solution))

# ============ Main ============

def main():
    init_db()
    error_msg = read_last_error()
    if not error_msg:
        return

    print("\n🟣 Last Error:")
    print(error_msg)

    solution = search_solution(error_msg)
    if solution:
        print("\n✅ [Cached Solution]:")
    else:
        print("\n🔵 [Gemini Suggestion]:")
        solution = ask_gemini(error_msg)
        save_solution(error_msg, solution)

    print("\n" + solution)

if __name__ == "__main__":
    main()
