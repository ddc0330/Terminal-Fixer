#!/usr/bin/env python3
import os
import sys
import sqlite3
import argparse
import google.generativeai as genai
from dotenv import load_dotenv
import json

#init
DB_PATH = "./fixerror.db"
LOG_PATH = "./logs/last_error.log"

# 獲取腳本所在目錄的絕對路徑
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_PATH = os.path.join(SCRIPT_DIR, ".env")

# 嘗試從腳本所在目錄載入 .env 檔案
if os.path.exists(ENV_PATH):
    print(f"✅ Loading .env file from {ENV_PATH}")
    load_dotenv(ENV_PATH)
else:
    # 如果找不到，嘗試從當前工作目錄載入
    print(f"⚠️ .env file not found at {ENV_PATH}, trying current directory")
    load_dotenv()

# 檢查環境變數是否正確載入
API_KEY = os.getenv("GEMINI_API_KEY")
if not API_KEY:
    print("❌ GEMINI_API_KEY not found in environment variables.")
    print("Please set your API key in the .env file or as an environment variable.")
    print("Example: GEMINI_API_KEY=your_api_key_here")
    print("Or run: export GEMINI_API_KEY=your_api_key_here")
    sys.exit(1)

print(f"✅ Using API key: {API_KEY[:5]}...{API_KEY[-5:]}")
genai.configure(api_key=API_KEY)

# init_db
def init_db():
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute('''
            CREATE TABLE IF NOT EXISTS error_solutions (
                error TEXT PRIMARY KEY,
                solution TEXT
            )
        ''')
        
# open error log saved locally
def read_last_error():
    if not os.path.exists(LOG_PATH):
        print("No error log found.")
        return None
    with open(LOG_PATH, "r") as f:
        return f.read()

# search solution from db
def search_solution(error_msg):
    with sqlite3.connect(DB_PATH) as conn:
        row = conn.execute("SELECT solution FROM error_solutions WHERE error=?", (error_msg,)).fetchone()
        return row[0] if row else None

# request to gemini
def ask_gemini(error_msg):
    try:
        model = genai.GenerativeModel('models/gemini-1.5-flash')
        prompt = f"""
You are a Linux terminal expert.
Given the following error message, directly provide the exact shell command(s) or specific steps to fix it.
Do not explain the cause, reason, or theory. Only output the solution.

Error:
{error_msg}
"""
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        print(f"❌ Error when querying Gemini API: {str(e)}")
        print("Please check your API key and internet connection.")
        return None

# save solution
def save_solution(error_msg, solution):
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute("INSERT OR REPLACE INTO error_solutions (error, solution) VALUES (?,?)", (error_msg, solution))

# list history on terminal
def show_history():
    with sqlite3.connect(DB_PATH) as conn:
        rows = conn.execute("SELECT error, solution FROM error_solutions").fetchall()
        if not rows:
            print("No history found.")
            return
        for i, (error, solution) in enumerate(rows, 1):
            print_error(f"=Error{i}:=")
            print(error)
            print(f"\033[91m===================================\033[0m")
            print_solution(f"=====Solution{i}:====")
            print(solution)
            print(f"\033[92m===================================\033[0m")

# add error/solution by self
def add_manual_entry():
    print("\n=== Add New Error Solution ===")
    print("Please input according to the following format:")

    cmd = input("[Command]      ")
    exit_code = input("[Exit Code]    ")
    errmsg = input("[Error Output] ")

    key = f"[Command]      {cmd}\n[Exit Code]    {exit_code}\n[Error Output] {errmsg}"

    print("\nYou entered:\n")
    print(key)

    solution = input("\nEnter the solution:\n")

    save_solution(key, solution)
    print("✅ Saved new entry.")

# delete entry you don't like
def delete_entry():
    with sqlite3.connect(DB_PATH) as conn:
        # 這裡修正！要 select error, solution
        rows = conn.execute("SELECT error, solution FROM error_solutions").fetchall()
        if not rows:
            print("❌ No entries to delete.")
            return

        for i, (error, solution) in enumerate(rows, 1):
            print_error(f"Error{i}:")
            print(error)
            print(f"\033[91m===================================\033[0m")
            print_solution(f"=====Solution{i}:====")
            print(solution)
            print(f"\033[92m===================================\033[0m\n")

        try:
            choice = int(input("Enter the number of the entry to delete: "))
            if choice < 1 or choice > len(rows):
                print("❌ Invalid selection.")
                return
            error_to_delete = rows[choice - 1][0]
            conn.execute("DELETE FROM error_solutions WHERE error=?", (error_to_delete,))
            print("✅ Deleted.")
        except ValueError:
            print("❌ Please enter a valid number.")
      
# clear all history in DB      
def clear_db():
    confirm = input("Are you sure you want to clear all records? (y/n): ")
    if confirm.strip().lower() == "y":
        with sqlite3.connect(DB_PATH) as conn:
            conn.execute("DELETE FROM error_solutions")
        print("✅ All records cleared.")
    else:
        print("❌ Operation cancelled.")

# search DB with error
def search_error(keyword):
    with sqlite3.connect(DB_PATH) as conn:
        rows = conn.execute("SELECT error, solution FROM error_solutions WHERE error LIKE ?", (f"%{keyword}%",)).fetchall()
        if not rows:
            print("No matching records found.")
            return
        for i, (error, solution) in enumerate(rows, 1):
            print_error(f"=Error{i}:=")
            print(error)
            print(f"\033[91m===================================\033[0m")
            print_solution(f"=====Solution{i}:====")
            print(solution)
            print(f"\033[92m===================================\033[0m")

# export json/md file 
def export_db(format):
    with sqlite3.connect(DB_PATH) as conn:
        rows = conn.execute("SELECT error, solution FROM error_solutions").fetchall()
    if not rows:
        print("No data to export.")
        return

    if format == "json":
        data = [{"error": error, "solution": solution} for error, solution in rows]
        with open("export.json", "w") as f:
            json.dump(data, f, indent=2)
        print("✅ Exported to export.json")

    elif format == "md":
        with open("export.md", "w") as f:
            for i, (error, solution) in enumerate(rows, 1):
                f.write(f"### Record {i}\n\n")
                f.write(f"**Error:**\n```\n{error}\n```\n\n")
                f.write(f"**Solution:**\n```\n{solution}\n```\n\n")
        print("✅ Exported to export.md")

    else:
        print("❌ Unsupported format, use --format md or --format json")

def print_error(title):
    print(f"\n\033[91m============={title}=============\033[0m")
    
def print_solution(title):
    print(f"\n\033[92m========{title}========\033[0m")
# main code
def main():
    init_db()
    
    parser = argparse.ArgumentParser(description="Terminal Fixer - AI Powered Error Solution CLI")
    parser.add_argument('--force', action='store_true', help="Force query AI without using cache")
    parser.add_argument('--history', action='store_true', help="Show all past solved errors")
    parser.add_argument('--add', action='store_true', help="Manually add error and solution to database")
    parser.add_argument('--delete', action='store_true', help="Delete an error record from database")
    parser.add_argument('--clear', action='store_true', help="Clear the entire database")
    parser.add_argument('--search', type=str, help="Search errors containing keyword")
    parser.add_argument('--export', choices=['md', 'json'], help="Export database to markdown or json")
    args = parser.parse_args()

    if args.history:
        show_history()
        return
    if args.add:
        add_manual_entry()
        return
    if args.delete:
        delete_entry()
        return
    if args.clear:
        clear_db()
        return
    if args.search:
        search_error(args.search)
        return
    if args.export:
        export_db(args.export)
        return
    
    # default is fixerror or fixerror --force
    error_msg = read_last_error()
    if error_msg is None:
        return
    error_msg = error_msg.rstrip('\n')
    if not error_msg:
        return

    print_error(" Error ")
    print(error_msg)
    print(f"\033[91m=================================\033[0m")

    solution = None
    solution = search_solution(error_msg)

    # -------- Case 1: DB 有快取且非 force --------
    if solution and not args.force:
        print_solution(" Cached Solution ")
        print(solution)
        print(f"\033[92m=================================\033[0m")
        return

    # -------- Case 2: force 或 DB 沒有 --------
    print_solution(" Gemini Solution ")
    new_solution = ask_gemini(error_msg)
    if new_solution is None:
        print("❌ Failed to get solution from Gemini API.")
        return
    print(new_solution)
    print(f"\033[92m=================================\033[0m")

    # -------- Case 2-1: 有快取情境下的安全覆蓋 --------
    if solution and args.force:
        confirm = input("A cached solution already exists. Do you want to overwrite it? (y/n): ")
        if confirm.strip().lower() == "y":
            save_solution(error_msg, new_solution)
            print("✅ Solution replaced.")
        else:
            print("❌ New solution discarded.")

    # -------- Case 2-2: 沒有快取，正常儲存 --------
    if not solution:
        confirm = input("Do you want to save this solution? (y/n): ")
        if confirm.strip().lower() == "y":
            save_solution(error_msg, new_solution)
            print("✅ Solution saved.")
        else:
            print("❌ Solution discarded.")

if __name__ == "__main__":
    main()
