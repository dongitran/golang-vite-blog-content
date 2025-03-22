Trong PostgreSQL, trường dữ liệu JSONB cung cấp một cách linh hoạt để lưu trữ và truy vấn dữ liệu JSON. Một tình huống thường gặp là cần cập nhật tất cả các đối tượng trong một mảng JSONB, ví dụ như điều chỉnh giá của các sản phẩm trong một danh sách. Trong bài viết này, chúng ta sẽ tìm hiểu cách thực hiện việc này bằng cách sử dụng hàm jsonb_set trong PostgreSQL.

Giả sử chúng ta có một bảng products trong PostgreSQL, mỗi hàng chứa một trường data kiểu dữ liệu JSONB. Trường data chứa một mảng các đối tượng, mỗi đối tượng đại diện cho một sản phẩm và có các thuộc tính như tên, giá, mô tả, v.v. Bây giờ, chúng ta muốn cập nhật tất cả các giá sản phẩm trong mảng này bằng cách tăng giá lên 10%.

Trước tiên, chúng ta cần tạo một bảng để lưu trữ dữ liệu JSONB:
```sql
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  data JSONB
);
```

Sau đó, chúng ta thêm một số dữ liệu mẫu vào bảng products:
```sql
INSERT INTO products (data)
VALUES ('{
  "items": [
    {"name": "Product A", "price": 10.0, "description": "Description A"},
    {"name": "Product B", "price": 20.0, "description": "Description B"},
    {"name": "Product C", "price": 30.0, "description": "Description C"}
  ]
}');
```

Chúng ta sẽ sử dụng câu lệnh SQL UPDATE kết hợp với hàm jsonb_set để cập nhật tất cả các đối tượng trong mảng.
```sql
UPDATE products
SET data = jsonb_set(
    data,
    '{items}',
    (
        SELECT jsonb_agg(
            jsonb_set(
                element,
                '{price}',
                (element->>'price')::numeric * 1.1  -- Tăng giá lên 10%
            )
        )
        FROM jsonb_array_elements(data->'items') AS element
    )
)
WHERE id = 1;
```
Trong câu lệnh UPDATE, chúng ta truyền vào bảng products và sử dụng hàm jsonb_set để cập nhật trường data. Đường dẫn '{items}' cho biết rằng chúng ta muốn cập nhật mảng "items" trong trường data.

Trong câu truy vấn con, chúng ta sử dụng jsonb_array_elements để duyệt qua từng phần tử trong mảng "items". Sau đó, chúng ta sử dụng hàm jsonb_set để cập nhật trường "price" của mỗi đối tượng. Trong ví dụ này, chúng ta tăng giá lên 10% bằng cách nhân giá hiện tại với 1.1.

Cuối cùng, chúng ta sử dụng điều kiện WHERE id = 1 để chỉ định rằng chúng ta chỉ muốn cập nhật hàng có id là 1.

Để kiểm tra kết quả, chúng ta có thể sử dụng câu lệnh SELECT:
```sql
SELECT * FROM products WHERE id = 1;
```

Kết quả sẽ hiển thị dữ liệu đã được cập nhật, với tất cả các giá sản phẩm trong mảng "items" đã được tăng lên 10%.

---
Cảm ơn các bạn đã theo dõi bài viết. Nếu có bất kỳ câu hỏi hoặc ý kiến nào, xin vui lòng để lại phản hồi bên dưới nhé ^^