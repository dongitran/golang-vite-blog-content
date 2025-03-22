Series Grafana Loki Kubernetes:
1. [Grafana Loki Kubernetes - Tìm hiểu cơ bản](https://viblo.asia/p/grafana-loki-kubernetes-tim-hieu-co-ban-part-13-PwlVm7jlJ5Z)
2. [Grafana Loki Kubernetes - Triển khai lên K8s](https://viblo.asia/p/grafana-loki-kubernetes-trien-khai-len-k8s-part-23-EoW4o3xo4ml)

![](https://images.viblo.asia/99c7777f-b7a3-4fdb-98bf-2a2023d48810.png)

# Giới thiệu chung

Grafana Loki là một hệ thống logging và lưu trữ log cho các hệ thống phân tán và điều khiển vận hành. Nó được tạo ra để hoạt động cùng với Grafana, một công cụ giám sát mã nguồn mở phổ biến, như một giải pháp toàn diện cho việc giám sát hệ thống.

Hiểu đơn giản thì Loki sẽ tự động nhặt nhạnh log từ các pod, container... và đưa chúng lên bảng điều khiển Grafana. Thế là chúng ta chỉ cần vào dashboard là đã có thể xem được mọi thông tin cần thiết rồi. Và mỗi khi deploy pod hoặc container mới, không cần setup gì thêm, Loki tự động nắm bắt!

> Với Loki, việc xem log trở nên nhẹ nhàng như việc lướt Facebook. Với những anh em Dev, log là một phần quan trọng của cuộc sống, giúp chúng ta mò mẫm những lỗi và tìm ra những cách khắc phục 😆

# Kiến trúc của Loki
Dịch vụ Loki được tạo ra bằng cách sử dụng một tập hợp các thành phần (hoặc modules). Distributor, ingester, querier và query frontend là bốn thành phần có sẵn để sử dụng.
![](https://images.viblo.asia/89420173-7a7b-474c-ab95-12fc532572bc.png)

### 📬 Distributor
Module distributor xử lý và xác nhận dữ liệu từ các client. Dữ liệu hợp lệ được chia nhỏ và truyền đến nhiều ingester để xử lý song song.

### 📥 Ingester
Dữ liệu được ghi vào lưu trữ dài hạn thông qua module ingester. Loki chỉ lưu trữ các siêu dữ liệu (metadata) thay vì lưu trữ dữ liệu log. AWS S3, Apache Cassandra, hoặc hệ thống tệp cục bộ là các ví dụ về lưu trữ đối tượng linh hoạt.

### 🕵️‍♂️ Querier
Module querier được sử dụng để xử lý các truy vấn của người dùng trên ingester và lưu trữ đối tượng. Các truy vấn được thực hiện trên lưu trữ cục bộ trước, sau đó là lưu trữ dài hạn.

### 🔍 Query Frontend
Module query frontend có thể cung cấp các điểm cuối API cho các truy vấn, cho phép các truy vấn lớn được song song hóa. Query frontend vẫn sử dụng các truy vấn, nhưng nó chia nhỏ các truy vấn lớn thành các truy vấn nhỏ hơn và thực hiện đọc log song song. Điều này rất hữu ích nếu bạn mới bắt đầu với Loki và không muốn thiết lập một querier chi tiết ngay lúc này.

# Loki hoạt động như nào?
![](https://images.viblo.asia/60047fdd-49e4-4cba-8482-7bdeb5312ce3.png)
### 📡 Pull Logs với Promtail
Promtail là một bộ thu log được tạo ra đặc biệt cho Loki. Nó sử dụng cùng cơ chế khám phá dịch vụ của Prometheus và có các tính năng tương tự để gắn thẻ, chuyển đổi và lọc logs trước khi đưa vào Loki. 

### 🗄️ Lưu Trữ Logs trong Loki
Nội dung của logs không được chỉ mục bởi Loki. Thay vào đó, các mục được phân loại vào các luồng và được gắn nhãn. Điều này không chỉ tiết kiệm tiền mà còn có nghĩa là các dòng log có thể được truy vấn trong vài mili giây sau khi được nhận bởi Loki. 

### 🔍 Sử dụng LogQL để Khám Phá
Để khám phá logs của bạn, hãy sử dụng ngôn ngữ truy vấn tiên tiến của Loki, LogQL. Chạy các truy vấn LogQL từ trong Grafana để xem logs của bạn cùng với các nguồn dữ liệu khác, hoặc sử dụng LogCLI nếu bạn thích dòng lệnh. 

### 🚨 Cảnh Báo Logs
Thiết lập các quy tắc cảnh báo cho Loki sử dụng trong khi nó đánh giá dữ liệu Syslog của Loki. Cấu hình Loki là bắt buộc để truyền các cảnh báo được tạo ra đến một Prometheus Alertmanager, nơi chúng sẽ được định tuyến đến nhóm phù hợp.

> Tóm lại, Grafana Loki là một công cụ mạnh mẽ cho việc lưu trữ và giám sát log trong môi trường phân tán. Loki giúp đơn giản hóa quá trình quản lý log và giám sát hệ thống, 1 công cụ mà anh em Dev không được bỏ qua 😝