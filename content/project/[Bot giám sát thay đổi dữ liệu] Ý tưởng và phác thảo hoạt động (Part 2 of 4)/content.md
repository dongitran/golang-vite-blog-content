# Vấn đề
Chào các anh em Dev 😁

Mình là 1 Dev Backend nên data đối với mình là rất quan trọng, do có liên quan đến tiền bạc và cũng sẽ ảnh hưởng đến công việc đối soát nếu thiếu hoặc sai số liệu.
> Thông thường những lúc test code mình hay vào database check lại dữ liệu (có những lúc lười thì ko 😝), mặt khác QC có những lúc ko để ý kiểm tra về mặt dữ liệu nên có sai sót xảy ra là điều dễ hiểu 🥲

Vì thế mà trong lúc code suy nghĩ vẩn vơ thì mình nghĩ sao không xây dựng 1 tool để check dữ liệu realtime, mỗi khi mình code xong và test từng function nào thì data sẽ hiển thị sự thay đổi ảnh hưởng như thế nào. Tìm hiểu một lúc thì mình tìm được giải pháp là dùng phương pháp database trigger khi có sự thay đổi, do bên mình dùng chủ yếu là postgresql và mongodb và cả 2 thằng này đều hỗ trợ.
> Chức năng trigger trong database sẽ giám sát database có sự thay đổi như insert/update/delete nào diễn ra ko, nếu có thì database sẽ tạo 1 trigger, từ đó mình gán trigger này để chạy 1 function để gửi thông báo cho server

Vậy thì giờ mình sẽ chọn cách để hiển thị message lên, may mắn là công ty mình sử dụng Telegram để liên lạc nội bộ, vì thế mình dùng luôn bot của Telegram để triển khai, mỗi khi có sự thay đổi dữ liệu thì gửi lên cho mình ngay lập tức 🤩

# Server thu thập dữ liệu thay đổi
Ngoài việc thu thập dữ liệu từ database thông qua trigger thì mình thu thập luôn dữ liệu tất cả topic của kafka proker
![](https://images.viblo.asia/1608ef31-2f91-4429-b0fb-7644d0514b98.png)

Và ở đây khi Server thu thập dữ liệu xong, thì vừa gửi dữ liệu lên Telegram thông qua Bot thì mình sẽ gửi data đó đến 1 kafka broker khác kafka broker này do mình dựng lên nhé

Vậy tại sao lại có kafka broker đó nữa?
## Ý tưởng lại nảy ra
Mình suy nghĩ tại sao có những dữ liệu thường hay có 1 format nhất định, thì sao mình không build thêm 1 server để tự động validate dữ liệu đó, thế là mình nghĩ ko code thêm vào Server thu thập dữ liệu đó nữa, mà bắn các message được tổng hợp từ nhiều nguồn khác nhau đó vào 1 broker mình tự xây dựng để phục vụ cho server validate dữ liệu

# Server tiền xử lý dữ liệu và Server validate dữ liệu
![](https://images.viblo.asia/9d98d0bc-2152-43df-9dbe-410b10199716.png)



  Cùng tham gia Group Telegram: [DevOps Learing](https://t.me/+izmvdOHL-vhhNGZl)

  ---