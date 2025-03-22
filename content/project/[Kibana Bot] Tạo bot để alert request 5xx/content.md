## Từ gợi ý của sếp

Tháng 5, tháng của những cơn mưa đầu mùa! Sếp mình bỗng gợi ý **Bun** - một javascript runtime mới có hiệu suất khá cao nếu so sánh với Nodejs hoặc Deno. 
> Điều đó làm mình khá rạo rực 😁️️️️️️

Ngay lúc đó mình vội vào xem tài liệu của của thằng Bun này như nào, thoạt nhìn có vẻ nó thay node, thay luôn dc cả npm khi add package vào project. Sau đó mình không ngần ngại cài luôn vào máy :)))))

## Ý tưởng thôi thúc

Nhưng mình đặt ra câu hỏi làm thế nào để làm quen với nó mà có động lực đây, thế là vừa code task ở công ty, vừa nghĩ vu vơ kiếm gì đó để code với thằng Bun này để xem nó như nào :)))))

Đang ngồi code và tìm ý tưởng thì bỗng có vài lỗi xuất hiện trên web của đối tác(đang UAT), thì trước tiên mình chạy lên kibana xem request và lỗi như nào, tự nhiên trong đầu loé ra ý tưởng tại sao mình ko làm 1 con bot, mình chỉ cần gõ url vào thì bot tự động query request trên kibana và gửi trực tiếp cho mình, khỏi mất công vào trang kibana và tìm thủ công nữa 😅️️️️️️

> Từ ý tưởng đó, mình vội lên kibana, check các request xem lấy data được không, nhưng duyệt qua hết các api thì ko có api nào trả về raw data, bỗng thấy 1 api là /bsearch và truyền vào params compress=true, tự hỏi có thể truyền = false không, do đó mình thử liền thì đúng là có thể lấy raw data thật, vậy là ok, ý tưởng khả thi 

> Như vậy là đã có 1 chút ý tưởng, nhưng vẫn suy nghĩ tiếp là nó thực tế không, khi làm xong thì anh em Dev chung team mình có thể sử dụng được không? Bot này có làm phiền mọi người quá không?

## Làm rõ ý tưởng

## Triển khai alert request 5xx

## Triển khai live request