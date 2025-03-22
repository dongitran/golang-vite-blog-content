Trong bài viết này, chúng ta sẽ tìm hiểu cách xoá một trường trong kiểu dữ liệu JSONB của PostgreSQL khi trường đó nằm bên trong một trường khác trong JSONB. Để minh họa quá trình này, chúng ta sẽ tạo một bảng mẫu và thực hiện việc xoá trường trong JSONB.

Đầu tiên, chúng ta cần tạo một bảng chứa kiểu dữ liệu JSONB. Dưới đây là câu lệnh SQL để tạo bảng:
```sql
CREATE TABLE data (
  id SERIAL PRIMARY KEY,
  payload JSONB
);
```

Tiếp theo, chúng ta sẽ chèn một số dữ liệu mẫu vào bảng:
```sql
INSERT INTO data (payload)
VALUES ('{"parent_field": {"nested_field": "value", "field_to_delete": "value_to_delete"}}');
```

Để xoá một trường trong JSONB khi nó nằm bên trong một trường khác, chúng ta sử dụng câu lệnh SQL sau:
```sql
UPDATE data
SET payload = jsonb_set(payload, '{parent_field}', (payload->'parent_field') - 'field_to_delete')
WHERE payload -> 'parent_field' -> 'field_to_delete' IS NOT NULL;
```

Trong ví dụ trên, chúng ta sử dụng câu lệnh UPDATE để cập nhật dữ liệu. Phần SET payload = jsonb_set(payload, '{parent_field}', (payload->'parent_field') - 'field_to_delete') chỉ định rằng chúng ta muốn xoá trường "field_to_delete" trong trường "parent_field" của JSONB. Phần WHERE payload -> 'parent_field' -> 'field_to_delete' IS NOT NULL đảm bảo rằng chỉ những bản ghi có trường "parent_field" chứa trường "field_to_delete" sẽ được cập nhật.

Cuối cùng, chúng ta có thể kiểm tra kết quả bằng cách truy vấn bảng dữ liệu:
```sql
SELECT * FROM data;
```

Kết quả sẽ cho thấy rằng trường "field_to_delete" đã được xoá khỏi trường "parent_field" trong JSONB.

----
Cách thứ 2 rườm rà hơn xíu, nếu bạn muốn thử thách bản thân để sử dụng các hàm json_each và array_agg :)))))
```sql
UPDATE data
SET payload = jsonb_set(
        payload, 
        '{parent_field}', 
        (
          SELECT ('{' || array_to_string(array_agg(to_json(calculationVal.key) || ':' || calculationVal.value), ',') || '}')::json
          FROM (
            SELECT *
            FROM json_each((payload->'parent_field')::json)
            WHERE "key" <> 'field_to_delete'
          ) AS calculationVal
        )::jsonb
      )
WHERE payload -> 'parent_field'->>'field_to_delete' IS NOT NULL;
```
Trong câu lệnh UPDATE trên, chúng ta sử dụng hàm jsonb_set để thay đổi giá trị của trường 'payload'. Trường này được cập nhật với một đối tượng JSON mới được tạo ra từ kết quả của câu truy vấn con. Câu truy vấn con sử dụng hàm json_each để chia nhỏ trường 'parent_field' thành các cặp khóa-giá trị, sau đó loại bỏ cặp khóa 'field_to_delete'. Kết quả cuối cùng được chuyển đổi thành đối tượng JSONB và được gán lại cho trường 'calculationVal'.

Đồng thời, điều kiện WHERE rule -> 'parent_field'->>'field_to_delete' IS NOT NULL được sử dụng để đảm bảo rằng chỉ những bản ghi có trường 'parent_field' chứa trường 'field_to_delete' mới được cập nhật.

--------
Đó là những cách bạn có thể xoá một trường trong JSONB khi trường đó nằm bên trong một trường khác của JSONB sử dụng câu lệnh SQL trong PostgreSQL. Việc này rất hữu ích trong việc quản lý và xử lý dữ liệu JSON trong cơ sở dữ liệu của bạn.

Cảm ơn các bạn đã theo dõi bài viết. Nếu có bất kỳ câu hỏi hoặc ý kiến nào, xin vui lòng để lại phản hồi bên dưới nhé ^^