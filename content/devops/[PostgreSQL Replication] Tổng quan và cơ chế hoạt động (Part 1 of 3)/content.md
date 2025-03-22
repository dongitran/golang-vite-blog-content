Series PostgreSQL Replication:
1. [PostgreSQL Replication - Tổng quan và cơ chế hoạt động](https://viblo.asia/p/postgresql-replication-tong-quan-va-co-che-hoat-dong-part-12-GAWVpyxo405)
2. [PostgreSQL Replication - Triển khai lên K8s](https://viblo.asia/p/postgresql-replication-xay-dung-ci-cd-de-deploy-tu-dong-part-23-y37LdvE04ov)
3. [PostgreSQL Replication - Xây dựng CI-CD để deploy tự động](https://viblo.asia/p/postgresql-replication-xay-dung-ci-cd-de-deploy-tu-dong-part-23-y37LdvE04ov)

![](https://images.viblo.asia/0ee87145-6b5f-41df-801a-bea9fe17a603.jpeg)

Đối với các hệ thống lớn thì việc scale database rất là quan trọng. Có nhiều phương pháp để scale database, từ việc tối ưu hóa cấu trúc dữ liệu và truy vấn, cho đến việc triển khai các giải pháp phân tán như sharding, replication và partitioning.
> Trong bài viết này mình đi cơ bản về replication trong postgresql nhé 😁

Replication là một kỹ thuật cho phép sao chép dữ liệu từ một node chính (master) sang các node sao chép (replica). Việc này không chỉ tăng khả năng chịu tải mà còn cung cấp tính sẵn sàng cao và khả năng phục hồi sau sự cố. Tuy nhiên, việc đồng bộ hóa dữ liệu giữa các replica có thể đối mặt với các vấn đề về hiệu suất và đồng nhất dữ liệu do cần phải tốn thêm tài nguyên phục vụ cho đồng bộ dữ liệu.

## Các loại Replication trong PostgreSQL

### 🚰 Streaming Replication
Streaming Replication là cách phổ biến nhất để sao chép dữ liệu trong PostgreSQL. Nó tạo ra một bản sao của cơ sở dữ liệu trên một máy chủ khác, dựa trên việc ghi nhật ký. Các bản ghi WAL (Write-Ahead Logging) được trực tiếp di chuyển từ máy chủ gốc sang máy chủ sao chép để áp dụng. Đây có thể coi là phương pháp phục hồi liên tục.

![](https://images.viblo.asia/b4aebc54-43ff-4b4d-a248-23229fb9f29a.png)

Có hai cách thực hiện phương pháp này: truyền theo đoạn WAL một lần (file-based) và truyền dựa trên các bản ghi WAL (record-based). Điều này thực hiện giữa máy chủ chính và máy chủ sao chép mà không cần chờ đợi việc điền tệp WAL.

Trong thực tế, có hai quá trình chính: WAL receiver chạy trên máy chủ sao chép kết nối với máy chủ chính qua TCP/IP, và WAL sender trên máy chủ chính gửi các bản ghi WAL đến máy chủ sao chép khi chúng được tạo ra.

### 🧠 Logical Replication
Logical Replication trong PostgreSQL là cách sao chép dữ liệu và các thay đổi dựa trên các định danh riêng. Nó hoạt động bằng cách đăng ký vào các "publication" trên một "publisher". Gồm 2 phần như sau
* Publication: Là một nhóm các thay đổi từ một hoặc nhiều bảng.
* Subscription: Là nơi lấy dữ liệu từ sao chép logic. Nó kết nối đến một cơ sở dữ liệu khác để lấy dữ liệu từ các publication mà nó muốn đăng ký.
![](https://images.viblo.asia/d78ae674-c8fd-49a3-9108-135161eb5b52.png)

Hiểu đơn giản thì nó sao chép dữ liệu dựa trên các thay đổi cụ thể trong dữ liệu (như các câu lệnh INSERT, UPDATE, DELETE) thay vì chỉ sao chép dữ liệu theo cấu trúc (như sao chép toàn bộ bảng). Điều này cho phép bạn sao chép dữ liệu một cách linh hoạt và chính xác hơn, đồng thời giảm tải cho hệ thống.

## Các chế độ Replication trong PostgreSQL
Sao chép trong PostgreSQL có thể là đồng bộ hoặc không đồng bộ.

### 🕰️ Asynchronous Replication
Trong chế độ này, dữ liệu có thể không được sao chép ngay lập tức sang máy chủ dự phòng. Có thể xảy ra mất dữ liệu nhỏ nếu máy chủ dự phòng không kịp theo kịp với tốc độ của máy chủ chính. Nếu rủi ro mất dữ liệu nhỏ này chấp nhận được, bạn có thể sử dụng chế độ này.

### 🔄 Synchronous Replication
Ở đây, mỗi cam kết của giao dịch ghi phải chờ xác nhận từ cả máy chủ chính và máy chủ dự phòng trước khi tiếp tục. Điều này giảm thiểu nguy cơ mất dữ liệu, vì cả hai máy chủ phải ghi nhận giao dịch trước khi nó được coi là hoàn tất. Tuy nhiên, thời gian phản hồi cho mỗi giao dịch sẽ tăng, do phải chờ đợi xác nhận từ cả hai máy chủ.

## Sự sẵn có cao cho PostgreSQL Replication
Sự sẵn có cao là một yêu cầu cho nhiều hệ thống, bất kể công nghệ chúng ta sử dụng, và có các phương pháp khác nhau để đạt được điều này bằng cách sử dụng các công cụ khác nhau.

### 🔁 Load Balancing
Cân bằng tải là các công cụ có thể được sử dụng để quản lý lưu lượng từ ứng dụng của bạn để tận dụng tối đa kiến trúc cơ sở dữ liệu của bạn. Không chỉ hữu ích cho việc cân bằng tải của cơ sở dữ liệu của chúng tôi, nó còn giúp ứng dụng được chuyển hướng đến các nút có sẵn/sống sót và thậm chí xác định cổng với các vai trò khác nhau.


### 💡 Cải Thiện Hiệu Suất Trên Sao Chép PostgreSQL
Hiệu suất luôn quan trọng trong bất kỳ hệ thống nào. Bạn sẽ cần tận dụng tốt các tài nguyên có sẵn để đảm bảo thời gian phản hồi tốt nhất có thể và có nhiều cách khác nhau để làm điều này. Mỗi kết nối đến cơ sở dữ liệu đều tiêu tốn tài nguyên nên một trong các cách để cải thiện hiệu suất trên cơ sở dữ liệu PostgreSQL của bạn là có một bộ quản lý kết nối tốt giữa ứng dụng và các máy chủ cơ sở dữ liệu của bạn.

Cùng tham gia Group Telegram: [DevOps Learing](https://t.me/+izmvdOHL-vhhNGZl)

---
Series PostgreSQL Replication:
1. [PostgreSQL Replication - Tổng quan và cơ chế hoạt động](https://viblo.asia/p/postgresql-replication-tong-quan-va-co-che-hoat-dong-part-12-GAWVpyxo405)
2. [PostgreSQL Replication - Triển khai lên K8s](https://viblo.asia/p/postgresql-replication-xay-dung-ci-cd-de-deploy-tu-dong-part-23-y37LdvE04ov)
3. [PostgreSQL Replication - Xây dựng CI-CD để deploy tự động](https://viblo.asia/p/postgresql-replication-xay-dung-ci-cd-de-deploy-tu-dong-part-23-y37LdvE04ov)