Cloud Run của Google Cloud Platform (GCP) cung cấp một nền tảng serverless để chạy các container được quản lý tự động. Kết hợp với GitHub Actions, bạn có thể tự động hóa quy trình triển khai (CI/CD) cho ứng dụng Node.js của mình.

Repository: https://github.com/dongtranthien/Cloud-Run-CI-CD-Template

## Bước 1: Chuẩn Bị Repository
Tạo một dự án Node.js cơ bản trong thư mục cục bộ của bạn:
```
mkdir MyCloudRunApp
cd MyCloudRunApp
npm init -y
```

Tiếp theo, tạo một file index.js với nội dung sau:
```
const http = require('http');

const hostname = '0.0.0.0';
const port = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/plain');
    res.end('Hello, World!\n');
});

server.listen(port, hostname, () => {
    console.log(`Server running at http://${hostname}:${port}/`);
});
```

Và tạo file Dockerfile:
```
FROM node:latest

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 8080

CMD ["node", "index.js"]
```

Cấu Hình GitHub Actions: 
Tạo thư mục .github/workflows trong repository của bạn và tạo file cloudrun.yml trong thư mục này và với nội dung sau:
```
name: Deploy to Google Cloud

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Google Cloud SDK
        run: |
          curl -o google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-372.0.0-linux-x86_64.tar.gz
          tar -xf google-cloud-sdk.tar.gz
          ./google-cloud-sdk/install.sh --quiet
          echo "${{ secrets.GCLOUD_AUTH }}" > /tmp/gcloud.json
          ./google-cloud-sdk/bin/gcloud auth activate-service-account --key-file=/tmp/gcloud.json
          ./google-cloud-sdk/bin/gcloud config set project cdtest-406103

      - name: Build Docker image
        run: |
          docker build -t nodejs-sample-image .

      - name: Configure Docker and push image
        run: |
          ./google-cloud-sdk/bin/gcloud auth configure-docker
          docker tag nodejs-sample-image gcr.io/cdtest-406103/nodejs-sample-image
          docker push gcr.io/cdtest-406103/nodejs-sample-image

      - name: Deploy to Google Cloud Run
        run: |
          ./google-cloud-sdk/bin/gcloud run deploy nodejs-sample-service \
            --image=gcr.io/cdtest-406103/nodejs-sample-image \
            --platform=managed \
            --region=us-central1 \
            --allow-unauthenticated
  send-notification-successful:
    needs: deploy
    runs-on: ubuntu-latest
    if: ${{ success() && needs.deploy.result == 'success' }}
    steps:
      - name: Send Telegram Notification
        env:
          TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHAT_ID: "${{ secrets.TELEGRAM_GROUP_DEPLOYMENTS }}"
        run: |
          curl -X POST \
            https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage \
            -d chat_id=${TELEGRAM_CHAT_ID} \
            -d text="🎉 <b>Cloud Run CI/CD Template</b> Deployment was successful!
            Your amazing tool is now available for everyone! 🚀✨" \
            -d parse_mode=HTML

  send-notification-failed:
    needs: deploy
    runs-on: ubuntu-latest
    if: ${{ failure() && needs.deploy.result == 'failure' }}
    steps:
      - name: Send Telegram Notification
        env:
          TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHAT_ID: "${{ secrets.TELEGRAM_GROUP_DEPLOYMENTS }}"
        run: |
          curl -X POST \
            https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage \
            -d chat_id=${TELEGRAM_CHAT_ID} \
            -d text="❌ Oh no! <b>Cloud Run CI/CD Template</b> Deployment failed!
            There might be something wrong with the process. 
            Please check it out! 🛠️🔍" \
            -d parse_mode=HTML
```


## Bước 2: Tạo Service Account và Khóa JSON
Truy cập vào Google Cloud Console và tạo một Service Account có quyền truy cập vào Cloud Run.
Tạo khóa JSON cho Service Account và lưu nó như một secret trên GitHub Repository của bạn với tên là GCLOUD_AUTH.

## Bước 3: Cấu Hình GitHub Secrets
Thêm các GitHub Secrets sau vào repository của bạn:

* GCLOUD_AUTH: Khóa JSON của Service Account.
* TELEGRAM_BOT_TOKEN: Token của bot Telegram.
* TELEGRAM_GROUP_DEPLOYMENTS: ID nhóm chat Telegram.

## Bước 4: Kích Hoạt Quy Trình CI/CD
Commit và push các thay đổi vào repository của bạn để kích hoạt quy trình CI/CD trên github action
Kiểm tra logs trong GitHub Actions để theo dõi quá trình triển khai và đảm bảo rằng ứng dụng được triển khai thành công.



-----


Với các bước này, bạn có thể tự động triển khai ứng dụng Node.js của mình lên Cloud Run thông qua GitHub Actions một cách dễ dàng và hiệu quả.