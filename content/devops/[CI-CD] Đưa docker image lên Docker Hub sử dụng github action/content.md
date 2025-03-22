![](https://images.viblo.asia/f4afc04f-84eb-433f-8e78-7689a756bcce.jpg)

Hôm nay mình sẽ chia sẻ về cách tự động đưa image Docker lên Docker Hub bằng Github Actions nhé, bước này là bước đầu tiên trong quá trình Continuous Deployment, code của bạn muốn deploy lên 1 server/cluster nào đó đều cần phải deploy và push image lên một trong các nền tảng lưu trữ docker image như aws, gcp,... 
> Ở đây mình sử dụng Docker Hub do free khi sử dụng repository image public 🙃

> Hãy tưởng tượng bạn đang phát triển một ứng dụng Golang "xịn sò". Sau mỗi lần thay đổi code, bạn lại phải thủ công "đẩy" ảnh Docker lên Docker Hub. Vừa tốn thời gian, vừa dễ mắc sai sót, đúng không nào?, tớ ví dụ vậy thôi chớ ít ai làm vậy 😁

Thành quả được sẽ như này nha, sẽ có bot telegram mỗi khi các bạn push code lên
![](https://images.viblo.asia/d37754a8-0fa7-4af6-be89-b5b59dd34189.png)

Bắt đầu luôn nào 😆

# Cấu hình project mẫu
Ở đây mình sẽ tạo 1 project golang để demo nhé

Trước tiên tạo thư mục code 
```bash
mkdir golang-push-image-docker-hub
cd golang-push-image-docker-hub
```

Tạo file main.go
```go
package main

import "fmt"

func main() {
    fmt.Println("Hello, Go!")
}
```
Tạo Dockerfile để build image nhé
```bash
FROM golang:1.19-alpine as builder
WORKDIR /app
COPY . .
RUN rm -rf .env .github .git
RUN go build -o main .

CMD ["./main"]
```

Như vậy cơ bản xong project code golang để demo rồi, với các ngôn ngữ khác cũng tương tự nha 😅

Ok, xong phần demo code, giờ đến lượt "nhân vật chính" của bài hôm nay, đó chính là cấu hình để build và push image lên docker hub
# Triển khai workflow cho github action
Mô hình như sau
![](https://images.viblo.asia/184eee9c-7430-42aa-8c51-f96c2d8662b0.png)

Trong đó thì chi tiết của workflow như sau
* Dùng telegram bot để gửi thông báo vào nhóm dev, các bạn có thể sử dụng các cách thông báo khác như discord hay slack đều được nha
* Tiến hành build Docker Image dựa trên code demo lúc nãy và gắn tag chính là số lần github action run để phân biệt các image sau mỗi lần deploy
* Sau khi deploy lên Docker Hub thì kiểm tra quá trình build và push image có lỗi hay ko để thông báo thông qua telegram bot để biết được trạng thái deploy 

Cơ bản các bước build và push image như trên, còn chi tiết các bạn tham khảo trong repository mẫu này nha: [golang-push-image-docker-hub](https://github.com/dongitran/golang-push-image-docker-hub)

Ở trong workflow mình sử dụng secrets để truyền các thông tin nhạy cảm nhé, gồm các biến sau:
* DOCKER_USERNAME, DOCKER_PASSWORD: là user name và password mà bạn đăng nhập vào Docker Hub
* TELEGRAM_BOT_TOKEN: bạn dùng BotFathers để tạo 1 bot và lấy token của bot đó nhé
* TELEGRAM_GROUP_DEPLOYMENTS: tạo 1 group chat trên telegram, sau đó add bot của bạn vào, rồi lấy id của group chat đó(mình lấy bằng cách sử dụng telegram web, lấy trên url khi truy cập vào group)
Các bạn cần setup các biến này vào trong phần **Setting** -> **Secrets and variables** -> **Actions** để cấu hình nha 

> Lưu ý ở đây do các project demo không cần bảo mật nhiều nên mình push image lên Docker Hub, những project quan trọng các bạn phải sử dụng repository private để lưu trữ nha. Docker Hub thì có cung cấp sẵn 1 repository private, hoặc các bạn có thể đưa image lên aws/gcp/....

Như vậy chúng ta đã có thể push image lên Docker Hub rồi 🥲

Các bạn có thắc mắc comment bên dưới nha 😍😍