Trên công ty có ông bạn mang con Raspberry Pi B+ lên công ty dựng server để giám sát mạng, thế là mình xin ké 1 chân vào để deploy gì đấy vui vui 😁

Thế là bắt đầu tìm ý tưởng lặt vặt dựng con server nodejs gì đấy lên cho vui

Nhưng đến đoạn deploy lên, thì thấy nếu update code phải pull git về rồi chạy lại mất thời gian quá, bèn nghĩ ra kế để deploy tự động 1 cách đơn giản nhất 

Ý tưởng bắt đầu nhen nhóm bằng việc từ source code mình dùng docker build ra image và push thẳng lên docker hub, và trên raspberry pi mình chạy script python để kiểm tra docker hub có update phiên bản image mới ko, nếu có thì pull image về và restart lại container 😅

Repository cho các bạn tham khảo: [Repository Demo](https://github.com/dongtranthien/sms-bot)..

### Triển thôi nào 🤪

## Tạo docker file để build image từ source nodejs
```bash
FROM node:latest

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY dist/ ./dist/

EXPOSE 3000

CMD ["node", "dist/app.js"]

```

## Tạo github workflow để build và push image lên Docker Hub
```bash
name: Deploy to Docker Hub

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
            -d text="🚀 <b>Sms Bot</b> Deployment has started!" \
            -d parse_mode=HTML

  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '14'

      - name: Install dependencies and build
        run: |
          npm install
          npm run build

      - name: Login to Docker Hub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Set up QEMU
        run: |
          sudo apt-get update
          sudo apt-get install -y qemu-user-static

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1

      - name: Build image for aarch64
        run: |
          docker buildx create --name builder --use
          docker buildx inspect builder --bootstrap
          docker buildx build --platform linux/arm64 -t ${{ secrets.DOCKER_HUB_IMAGE_NAME }}:latest --push .

  send-notification-successful:
    needs: build
    runs-on: ubuntu-latest
    if: ${{ success() && needs.build.result == 'success' }}
    steps:
      - name: Send Telegram Notification
        env:
          TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHAT_ID: "${{ secrets.TELEGRAM_GROUP_DEPLOYMENTS }}"
        run: |
          curl -X POST \
            https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage \
            -d chat_id=${TELEGRAM_CHAT_ID} \
            -d text="🎉 <b>Sms Bot</b> Deployment to docker hub was successful!" \
            -d parse_mode=HTML

  send-notification-failed:
    needs: build
    runs-on: ubuntu-latest
    if: ${{ failure() && needs.build.result == 'failure' }}
    steps:
      - name: Send Telegram Notification
        env:
          TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHAT_ID: "${{ secrets.TELEGRAM_GROUP_DEPLOYMENTS }}"
        run: |
          curl -X POST \
            https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage \
            -d chat_id=${TELEGRAM_CHAT_ID} \
            -d text="❌ Oh no! <b>Sms Bot</b> Deployment failed!
            There might be something wrong with the process. 
            Please check it out! 🛠️🔍" \
            -d parse_mode=HTML
```

## Script python để pull và restart Docker image
```python
import docker
import time
import logging
from logging.handlers import RotatingFileHandler
from telegram import Bot
import requests

TELEGRAM_BOT_TOKEN = ''
TELEGRAM_CHAT_ID = ''

def send_telegram_message(message):
    bot = Bot(token=TELEGRAM_BOT_TOKEN)
    bot.send_message(chat_id=TELEGRAM_CHAT_ID, text=message, parse_mode='HTML')

log_formatter = logging.Formatter('%(asctime)s - %(levelname)s: %(message)s')
log_handler = RotatingFileHandler('logs.log', maxBytes=1024 * 1024, backupCount=5)
log_handler.setFormatter(log_formatter)
logger = logging.getLogger()
logger.addHandler(log_handler)
logger.setLevel(logging.INFO)

def get_image_info(image_name):
    try:
        response = requests.get(f"https://hub.docker.com/v2/repositories/{image_name}/tags/latest")
        if response.status_code == 200:
            image_info = response.json()
            return image_info
        else:
            print(f"Failed to get image info, status code: {response.status_code}")
            return None
    except requests.RequestException as e:
        print(f"Request error: {e}")
        return None

def check_and_update_image(container_name, image_name):
    client = docker.from_env()

    logger.info(f"Start pull image..")

    try:
        version = get_image_info(image_name)
        digest = image_name + '@' + version['digest']
        
        container = client.containers.get(container_name)
        current_image_id = container.image.id
        current_image_digest = container.image.attrs['RepoDigests'][0] if 'RepoDigests' in container.image.attrs else None

        logger.info(f"current_image_id {current_image_id}")
        logger.info(f"current_image_digest {current_image_digest}")
        logger.info(f"digest {digest}")

        if current_image_digest != digest:
            logger.info("Updating...")
            send_telegram_message("🚀 <b>Auto Pull Docker - Raspberry pi</b> Deployment has started!")
            client.images.pull(image_name)
            container.stop()
            container.remove()

            client.containers.run(image_name, detach=True, name=container_name, volumes={
                '/home/dongtran/py/.env': {'bind': '/usr/src/app/.env', 'mode': 'rw'}
            })
            logger.info("Container update successful.")
            send_telegram_message("🚀 <b>Auto Pull Docker - Raspberry pi</b> Deployment on raspberry pi sucessful!")
        else:
            logger.info("No action.")
    except docker.errors.NotFound as e:
        logger.error(f"Container '{container_name}' not found: {e}")
        return
    except docker.errors.APIError as e:
        logger.error(f"APIError: {e}")
        return
    except docker.errors.ImageNotFound:
        logger.error(f"Image '{image_name}' not exist")
        return

if __name__ == "__main__":
    container_name = ""
    image_name = ""

    while True:
        check_and_update_image(container_name, image_name)
        time.sleep(30)
```


-----
Như vậy chúng ta đã có thể deploy ứng dụng 1 cách tự động trên raspberry pi rồi 🥲

Các bạn có thắc mắc comment bên dưới nha 😍😍