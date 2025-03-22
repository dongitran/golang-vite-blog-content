Tiếp nối bài viết lần trước mình đã [deploy ứng dụng lên cloud run của GCP](https://viblo.asia/p/ci-cd-trien-khai-ung-dung-nodejs-len-cloud-run-voi-github-actions-018J2Mn04YK) rồi thì hôm nay mình sẽ tiếp tục deploy thử ứng dụng lên Kubernetes Engine nhé 😆 

Và đôi lời một chút với Kubernetes, nó là một nền tảng mạnh mẽ để quản lý và triển khai ứng dụng mà hầu hết các ứng dụng lớn hiện nay đều sử dụng, hãy cùng mình khám phá nhé!

Repository: https://github.com/dongtranthien/Kubernetes-Engine-CI-CD-Template

![](https://images.viblo.asia/b3556be8-3450-48d7-80e0-65ffdfffe31a.jpg)

## Bước 1: Tạo project nodejs cơ bản
Khởi tạo thư mục dự án
```bash
mkdir Kubernetes-Engine-CI-CD-Template
cd Kubernetes-Engine-CI-CD-Template
npm init -y
```
Tạo file index.js với mã nguồn tạo một server web cơ bản, đoạn mã nguồn tạo một server web đơn giản để trả về chuỗi "Hello, World!" khi truy cập địa chỉ cụ thể.
```js
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

## Bước 2: Tạo Dockerfile
File này dùng để build ra image để chạy trên container
```js
FROM node:latest            // Sử dụng image Node.js làm base image

WORKDIR /usr/src/app        // Thiết lập thư mục làm việc trong container

COPY package*.json ./       // Copy tập tin package.json và package-lock.json vào thư mục làm việc

RUN npm install             // Cài đặt các dependencies của ứng dụng

COPY . .                    // Copy toàn bộ nội dung của thư mục hiện tại vào thư mục làm việc trong container

EXPOSE 8080                 // Khai báo cổng 8080 để ứng dụng có thể được truy cập từ bên ngoài

CMD ["node", "index.js"]    // Chạy ứng dụng Node.js khi container được khởi chạy
```

## Bước 3: Tạo Github action để chạy các tiến trình CI CD
Trước khi bước vào job chính deploy lên gcp thì mình có thêm các job gửi tin nhắn đến group telegram để thông báo bắt đầu và kết thúc quá trình.
Mình mô tả xíu về các step để deploy:
* Checkout mã nguồn từ repository.
* Thiết lập Google Cloud SDK.
* Cấu hình Docker CLI để làm việc với Container Registry.
* Xây dựng Docker image từ mã nguồn và đẩy image lên Container Registry.
* Cài đặt kubectl để quản lý Kubernetes.
* Lấy thông tin xác thực và cấu hình kubectl để truy cập Cluster.
* Áp dụng các cấu hình triển khai từ file deployment.yaml lên Kubernetes.
```
name: Deploy to Kubernetes

on:
  push:
    branches:
      - main

jobs:
  send-notification-started:
    runs-on: ubuntu-latest
    steps:
      - name: Send Telegram Notification
        env:
          TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHAT_ID: "${{ secrets.TELEGRAM_GROUP_DEPLOYMENTS }}"
        run: |
          curl -X POST \
            https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage \
            -d chat_id=${TELEGRAM_CHAT_ID} \
            -d text="🚀 <b>Kubernetes Engine CI-CD Template</b> Deployment has started!
            Your deployment process is in progress. 🛠️🔍" \
            -d parse_mode=HTML

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
          ./google-cloud-sdk/bin/gcloud config set project ${{ secrets.GCP_PROJECT_ID }}

      - name: Configure Docker CLI
        run: |
          ./google-cloud-sdk/bin/gcloud auth configure-docker

      - name: Build and push Docker image
        run: |
          docker build -t gcr.io/${{ secrets.GCP_PROJECT_ID }}/kubernetes-engine-ci-cd-template .
          docker push gcr.io/${{ secrets.GCP_PROJECT_ID }}/kubernetes-engine-ci-cd-template

      - name: Install kubectl plugin
        run: |
          ./google-cloud-sdk/bin/gcloud components install kubectl

      - name: Set kubectl context
        run: |
          ./google-cloud-sdk/bin/gcloud container clusters get-credentials ${{ secrets.GCP_CLUSTER_NAME }} --zone ${{ secrets.GCP_CLUSTER_ZONE }} --project ${{ secrets.GCP_PROJECT_ID }}

      - name: Configure kubectl
        run: |
          gcloud auth activate-service-account --key-file=/tmp/gcloud.json
          kubectl config set-credentials gke-cluster-user --token=$(gcloud auth print-access-token)
          kubectl config set-context gke-cluster --cluster=${{ secrets.GCP_CLUSTER_CONTEXT }} --user=gke-cluster-user
          kubectl config use-context gke-cluster

      - name: Deploy to Kubernetes
        run: |
          kubectl apply -f deployment.yaml
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
            -d text="🎉 <b>Kubernetes Engine CI-CD Template</b> Deployment was successful!
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
            -d text="❌ Oh no! <b>Kubernetes Engine CI-CD Template</b> Deployment failed!
            There might be something wrong with the process. 
            Please check it out! 🛠️🔍" \
            -d parse_mode=HTML
```

## Bước 4: Tạo file deployment.yaml để tạo workload, pod auto scaler và service
* Tạo workload: nhầm xác định số lượng replicas (bản sao) của ứng dụng chúng ta muốn triển khai, lưu ý phải từ 2 trở lên nha, nếu bạn chỉ dùng 1 thì khi deploy bản mới lên thì workload ko có pod để chạy bản mới của bạn đâu(khi chạy xong pod mới thì pod cũ sẽ tắt đi nhé)
* Tạo HorizontalPodAutoscaler: phần này sẽ tự động mở rộng số lượng Pods dựa trên tài nguyên sử dụng (trong trường hợp này, CPU)
* Tạo service: để tạo một dịch vụ để có thể truy cập vào ứng dụng từ bên ngoài
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-1
  namespace: default
  labels:
    app: nginx-1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-1
  template:
    metadata:
      labels:
        app: nginx-1
    spec:
      containers:
        - name: nginx-container
          image: gcr.io/cdtest-406103/kubernetes-engine-ci-cd-template:latest
          ports:
            - containerPort: 8080

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-1-hpa-zylx
  namespace: default
  labels:
    app: nginx-1
spec:
  scaleTargetRef:
    kind: Deployment
    name: nginx-1
    apiVersion: apps/v1
  minReplicas: 1
  maxReplicas: 2
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: default
spec:
  selector:
    app: nginx-1
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer
```


-----
Chúng ta đã hoàn thành quá trình triển khai ứng dụng lên Kubernetes Engine. 

Việc sử dụng Kubernetes giúp quản lý và mở rộng ứng dụng của bạn trở nên linh hoạt và mạnh mẽ hơn. Bài viết này mong muốn giúp bạn hiểu rõ hơn về quá trình triển khai trên môi trường Kubernetes và ứng dụng nó vào công việc thực tế của bạn. Hãy tiếp tục khám phá và tận dụng sức mạnh của Kubernetes nhé, chúc các bạn thành công!

Có thắc mắc gì các bạn cứ comment bên dưới nha 😁