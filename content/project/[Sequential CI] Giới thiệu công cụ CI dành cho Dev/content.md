### Vấn đề mình gặp phải, còn bạn thì sao 🥲
Trong quá trình dev Back-End thì mình thấy một số vấn đề như sau ae xem thử có giống mình ko nhé 😅
* Lười test lại code
* Nghĩ code thay đổi ít quá, và tự tin không lỗi nhưng đầy bug 
* Không nhớ feature mình lên ảnh hưởng đến luồng/api nào khác

> Vì thế mà ra khá nhiều bug do tính chủ quan và những lỗi mình ko kiểm soát được 😔

Do đó mình nghĩ ra và tự build project **Sequential CI** để khắc phục việc test lại các luồng cũ, tự động validate các luồng liên quan có ảnh hưởng gì không. Nghe sơ qua thì cũng giống tương tự với việc automation test nhưng áp dụng cho dev:
* Xây dựng việc tự động test api, test được lần lượt api
* Có thể query được dữ liệu từ các CSDL như postgres, mongo, mysql,..
* Lưu được dữ liệu trong quá trình chạy để các api/query có thể sử dụng data với nhau
* Có thể validate dc dữ liệu từ api hoặc query từ DB lên

Do đó ý tưởng của project Sequential CI của mình lên như sau
![](https://images.viblo.asia/b9963f0e-c9de-4a0a-9db9-dbf7b4adb33d.png)

> Có thể hiểu đây là quá trình nối tiếp nhau, chạy lần lượt từng process (chạy api, query db, validate dữ liệu, tạo dữ liệu,...) và những process này sẽ lưu data trong quá trình chạy để các process khác có thể sử dụng. Mục đích để chạy hoàn chỉnh 1 task vụ nào đó

### Ví dụ về luồng api đặt vé máy bay
![](https://images.viblo.asia/29e0bb91-40ad-45a5-af49-95a7423966fd.png)

### Mình đã nêu cơ bản ý tưởng của **Sequential CI**, mời các bạn cùng đóng góp thêm ý kiến nha 🤤
### Repository dự án: https://github.com/dongtranthien/Sequential-CI