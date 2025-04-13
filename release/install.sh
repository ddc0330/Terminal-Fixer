#!/bin/bash

echo "===== Terminal Fixer Docker Installer ====="

# 檢查 Docker 是否安裝
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安裝，請先安裝 Docker"
    echo "安裝指南: https://docs.docker.com/get-docker/"
    exit 1
fi

# 檢查 Docker Compose 是否安裝
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安裝，請先安裝 Docker Compose"
    echo "安裝指南: https://docs.docker.com/compose/install/"
    exit 1
fi

# 建立必要的目錄
mkdir -p logs

# 複製環境變數範例
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ 已建立 .env 檔案，請編輯並設定您的 API 金鑰"
fi

# 建立 Docker 映像
echo "建立 Docker 映像..."
docker build -t terminal-fixer:latest -f Dockerfile .

# 啟動服務
echo "啟動服務..."
docker-compose up 