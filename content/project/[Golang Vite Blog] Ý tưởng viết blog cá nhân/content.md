## Tìm ý tưởng
Hi anh em Dev, có thể một vài anh em cũng có 1 số bài viết Blog trên nền tảng cá nhân hoặc trên các trang hỗ trợ tạo bài viết như medium hoặc viblo,... thì đa phần mình phải vào trang web đó và viết bài

Còn nếu tự tạo Blog cá nhân thì có thể dùng wordpress, hoặc dev luôn cả FE BE cho web

Mà làm theo kiểu lối mòn thì chán quá 😝

Suy nghĩ quài mình nảy ra ý tưởng, có cách nào vừa tạo, vừa quản lý các bài viết trên github không, sẽ viết bài trên vscode, commit lên git thì bài viết tự động đồng bộ lên web luôn
> Mình nghĩ ngay ra áp dụng github action để thực hiện việc tự động đồng bộ bài viết lên 1 database nào đó, mình thì chọn postgresql nhé :))))

## Phác thảo ý tưởng

![](https://images.viblo.asia/a3731139-4258-4ddd-8252-4b0d78f600c6.png)

Ở đây mình sử dụng 2 repository nhé, 1 repository dùng cho việc lên nội dung các bài Blog và phần github workflow để **insert** các bài viết vào database **postgresql**

Còn respository còn lại là source code phần FE và BE của Blog


> Bắt đầu triển khai thôi nào!!

## Tạo content và tự động deploy dữ liệu lên Postgres
Trước khi lưu dữ liệu vào postgresql thì mình muốn tự động cả việc tạo database và table nếu postgresql chưa tồn tại 🤤

Cái này có ích mỗi khi mình deploy lại ở 1 server khác hay thay đổi database

Do đó trong github action mình sẽ cài đặt **postgresql-client** để kết nối đến postgresql

### Setup Job và cài đặt postgresql client
```bash
create-database-and-table-and-insert-content:
  runs-on: ubuntu-latest

  steps:
  - name: Install PostgreSQL client
    run: |
      sudo apt-get update
      sudo apt-get install --yes postgresql-client
```

### Tạo database
Thêm step tạo database nếu database chưa tồn tại
```bash
- name: Create database if not exists
  env:
    PGPASSWORD: ${{ secrets.DB_PASSWORD }}
  run: |
    result=$(psql -h ${{ secrets.DB_HOST }} -d ${{ secrets.DB_NAME_DEFAULT }} -U ${{ secrets.DB_USERNAME }} -p ${{ secrets.DB_PORT }} -tAc "SELECT 'CREATE DATABASE blog' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'blog');")
    if [ "$result" = "CREATE DATABASE blog" ]; then
        echo Create database
        psql -h ${{ secrets.DB_HOST }} -d ${{ secrets.DB_NAME_DEFAULT }} -U ${{ secrets.DB_USERNAME }} -p ${{ secrets.DB_PORT }} -c "CREATE DATABASE blog;"
    fi
```

### Xóa và tạo lại mới table
Tiếp theo là xoá table và tạo lại mới, nhược điểm của việc này là mỗi khi mình deploy thì sẽ có 1 khoảng thời gian downtime, nhưng ưu điểm là mình có thể thay đổi scheme bất cứ lúc nào 🤪

Ngoài cách của mình thì có thể có vài cách khác tốt hơn như dùng prisma,... để sau này mình tìm hiểu rồi cập nhật thêm kkkk
```bash
- name: Drop table if exists and recreate table
  run: psql -h ${{ secrets.DB_HOST }} -d ${{ secrets.DB_NAME }} -U ${{ secrets.DB_USERNAME }} -p ${{ secrets.DB_PORT }} -f sql/create-table.sql
  env:
    PGPASSWORD: ${{ secrets.DB_PASSWORD }}
```
File sql để tạo table
```sql
drop table if exists contents; 
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE IF NOT EXISTS contents (
  id                        SERIAL              PRIMARY KEY,
  uuid                      UUID                UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
  title                     VARCHAR             NOT NULL,
  content                   TEXT                NOT NULL,
  params                    JSONB               NOT NULL,
  banner_image              VARCHAR(255)        NOT NULL,
  created_at                TIMESTAMP           NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  created_by                VARCHAR(255)        NOT NULL,
  updated_at                TIMESTAMP                   ,
  updated_by                VARCHAR(255)                ,
  deleted_at                TIMESTAMP                   ,
  deleted_by                VARCHAR(255)                
);
```

### Checkout source code
Cần checkout đến source code để lấy content
```
  - name: Checkout repository
    uses: actions/checkout@v2
```

### Chuyển dữ liệu từ github sang sql để insert content
Mình sử dụng bash script để chuyển dữ liệu từ các file trong content github để build các câu lệnh insert
```bash
  - name: Run script to generate insert sql
    run: |
      chmod +x run.sh 
      ./run.sh
```

Về cấu trúc thư mục chứa các bài viết mình tổ chức folder như sau
```bash
  - repository
    - content
      - topic
        - post title name
          - content.md 
          - description.json
```

Khi ấy mình cần tạo script để duyệt qua toàn bộ topic của content, sau đó duyệt qua toàn bộ các bài viết của topic đó, và sau đó trong mỗi bài viết mình sẽ lấy dữ liệu ở cả 2 file content(nội dung vài blog) và description(chứa title, banner,...) để tạo câu sql để insert vào postgresql, do đó file run.sh như sau

```bash
#!/bin/bash

if [ -d "content" ]; then
    rm -f sql/insert.sql

    for dir in content/*; do
      for dir2 in $dir/*; do
        echo "Processing $dir2"
        if [ -d "$dir2" ]; then
            title=$(jq -r '.title' "$dir2/description.json")
            banner_image=$(jq -r '.banner_image' "$dir2/description.json")
            content=$(cat "$dir2/content.md")
            content=$(echo "$content" | sed "s/'/''/g")
            created_at=$(jq -r '.created_at' "$dir2/description.json")
            params=$(jq -r '.params' "$dir2/description.json")
            
            echo "INSERT INTO contents (title, content, banner_image, params, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by)" >> sql/insert.sql
            echo "VALUES ('$title', '$content', '$banner_image', '$params', '$created_at', 'dongtran', NULL, NULL, NULL, NULL);" >> sql/insert.sql
        fi
      done
    done

    echo "SQL file generated successfully."
else
    echo "Content directory not found in the project."
    exit 1
fi

```

### Chạy lệnh insert dữ liệu vào postgresql
```bash
  - name: Insert data into table
    run: psql -h ${{ secrets.DB_HOST }} -d ${{ secrets.DB_NAME }} -U ${{ secrets.DB_USERNAME }} -p ${{ secrets.DB_PORT }} -f sql/insert.sql
    env:
      PGPASSWORD: ${{ secrets.DB_PASSWORD }}
```

Vậy là đã xong tất cả các bước để tự động deploy dữ liệu từ github sang postgres để có thể hiển thị lên blog, mỗi khi mình viết bài xong, chỉ cần push code lên và đợi trong chưa đầy 1 phút là nội dung đã được cập nhật rồi, sướng phải không nhỉ 😝

Các bạn tham khảo thêm về repository về blog của mình nhé: [https://github.com/dongitran/blog-content-auto-deployment](https://github.com/dongitran/blog-content-auto-deployment)

Trong repository của mình có thêm trong workflow để gửi thông báo về telegram để theo dõi quá trình deploy nữa nha 🤗

## Xây dựng source code cho Blog
Đã có dữ liệu sẵn sàng trong database, giờ ta sẽ xây dựng frontend và backend cho Blog, về phần frontend mình chọn Vite và backend mình chọn Golang 

Bên dưới là template blog mình đã xây dựng sẵn, nói chung cũng khá đơn giản, chỉ cần dựng vài page UI cho FE và phía BE cũng chỉ xây dựng vài api để query postgresql để lấy dữ liệu

[https://github.com/dongitran/golang-vite-blog](https://github.com/dongitran/golang-vite-blog)

Các bạn có thể tùy biến thêm UI cho bản thân nhé :))))))

#### Bài viết của mình dừng ở đây 😛 Chủ yếu nêu ra một ý tưởng khác để tạo 1 Blog cá nhân, chúc các bạn có nhiều ý tưởng khác nữa nhé 😋
