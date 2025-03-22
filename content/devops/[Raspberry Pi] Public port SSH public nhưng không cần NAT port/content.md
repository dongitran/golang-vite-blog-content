### Vấn đề
Với các bạn đang dùng Raspberry Pi để làm server cho web hoặc app, chúng ta hay remote ssh trong cùng 1 mạng lan để build và deploy trên thiết bị

> Với cách này thì chúng ta không thể remote ở những mạng khác được nên hơi bất tiện 🥲

### Giải pháp
Mình nghĩ ra 1 cách để có thể public port 22 bằng ngrok với lệnh `ngrok tcp 22`, khi ấy ngrok sẽ tạo 1 link tcp và port để mình connect đến ở mọi nơi

>  Tuy nhiên sử dụng bản miễn phí thì link tạo ra từ ngrok luôn dc tạo mới khi mình restart lại, nên phải cần remote local để lấy lại link, khá phiền phức 🤨

### Ý tưởng 
Do đó mình nảy ra ý tưởng là mỗi lần restart thiết bị thì sẽ gửi link ngrok đến Telegram thông qua bot
![](https://images.viblo.asia/11905f48-ba5e-4358-815b-e189ccb0ed9c.png)

### Triển khai thôi nào 😋
Mình nghĩ ngay đến việc dùng python để chạy các lệnh đó trong terminal mỗi khi thiết bị khởi động và tự động gửi lên group của telegram 
```python
from telegram.ext import Updater, CommandHandler, MessageHandler, Filters
import time
import subprocess
import json
import os
import platform

GROUP_ID = ''

def start(update, context):
    update.message.reply_text('Wellcome!')

def startNgrok():
    command = "ngrok tcp 22"

    if platform.system().lower() == 'windows':
        command = f"runas /user:{os.environ['USERDOMAIN']}\\{os.environ['USERNAME']} {command}"
    else:
        command = f"{command}"

    subprocess.Popen(command, shell=True, start_new_session=True)
    time.sleep(5)
    commandGetInfo = "curl http://localhost:4040/api/tunnels"
    resultGetInfo = subprocess.run(commandGetInfo, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    data = json.loads(resultGetInfo.stdout)
    tunnels = data["tunnels"]
    
    return tunnels[0]["public_url"]

def handle_text_message(update, context):
    user_message = update.message.text
    if user_message != 'getlink':
        return
    
    result = startNgrok()
    
    update.message.reply_text('  🚁 Start ngrok successful\n' + result)

def main():
    updater = Updater(token='', use_context=True)
    dp = updater.dispatcher

    updater.bot.send_message(chat_id=GROUP_ID, text=' 🚀 Device Restart...')
    resultStart = startNgrok()
    updater.bot.send_message(chat_id=GROUP_ID, text=resultStart)

    dp.add_handler(CommandHandler('start', start))
    dp.add_handler(MessageHandler(Filters.text & ~Filters.command, handle_text_message))

    updater.start_polling()
    updater.idle()

if __name__ == '__main__':
    main()
```