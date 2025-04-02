FROM python:3.12-slim

# 建立工作目錄
WORKDIR /app

# 複製專案檔案到容器
COPY . /app

# 安裝依賴
RUN pip install --no-cache-dir -r requirements.txt

# 設定 logs 和 db 資料夾（volume 可用）
RUN mkdir -p /app/logs

# 加入環境變數 (可選)
ENV PYTHONUNBUFFERED=1

# 預設指令入口
ENTRYPOINT ["python", "fixerror.py"]
