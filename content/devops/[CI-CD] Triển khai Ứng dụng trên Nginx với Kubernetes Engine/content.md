Tiếp nối với bài hôm trước [Triển khai Ứng dụng lên Kubernetes Engine của Google Cloud Platform](https://viblo.asia/p/ci-cd-trien-khai-ung-dung-len-kubernetes-engine-cua-google-cloud-platform-obA46yrXVKv) thì hôm nay mình sẽ giới thiệu cách để sử dụng thêm Nginx  😋 🚀

Repository để các bạn có thể kéo về tham khảo: [Kubernetes-Nginx-CI-CD-Template](https://github.com/dongtranthien/Kubernetes-Nginx-CI-CD-Template)

![](https://images.viblo.asia/b5e2e192-54d1-4c2e-b32d-868bc72cb65f.png)

## Cấu hình nginx
Đầu tiên, để sử dụng Nginx, chúng ta cần tạo file nginx.conf để cấu hình hoạt động. Dưới đây là một ví dụ cấu hình cơ bản để lắng nghe trên cổng 80 và chuyển hướng từ service nodejs-service:

```bash
events {}

http {
  server {
    listen 80;

    location / {
      proxy_pass http://nodejs-service;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }
  }
}
```

Sau đó, tạo Dockerfile để build image Nginx và copy file nginx.conf vào image:
```bash
FROM nginx:latest

COPY nginx/nginx.conf /etc/nginx/nginx.conf
```

## Build image nginx và push lên google container registry
Như vậy là mình đã cấu hình xong để triển khai Nginx. Tiếp theo, thêm lệnh vào GitHub workflow để build image và đẩy lên GCR:
```base
- name: Build and push Nginx Docker image
        run: |
          docker build -t gcr.io/${{ secrets.GCP_PROJECT_ID }}/nginx-app:latest -f nginx/Dockerfile .
          docker push gcr.io/${{ secrets.GCP_PROJECT_ID }}/nginx-app:latest
```

## Tạo file config k8s
Sau khi image được đẩy lên GCR, chúng ta tạo file cấu hình để deploy lên Kubernetes. 
Dưới đây là file nginx-deployment.yaml:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: gcr.io/cdtest-406103/nginx-app:latest
          ports:
            - containerPort: 80
```
Trong đó
* Deployment: Mô tả cách Kubernetes sẽ chạy ứng dụng.
* replicas: Số lượng bản sao của ứng dụng Nginx sẽ chạy, ở đây là 2 bản sao.
* selector: Chỉ định Pods nào sẽ được triển khai, dựa trên labels.
* template: Định dạng cho các Pods mới.
* containers: Cài đặt container.
* image: Image của Nginx sẽ được sử dụng.
* ports: Cổng mà Nginx sẽ lắng nghe yêu cầu, ở đây là cổng 80.

File nginx-service.yaml để cấu hình service:
```
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
```
Trong đó:
* Service: Định nghĩa cách truy cập vào ứng dụng.
* selector: Xác định các Pods mà Service sẽ định tuyến yêu cầu đến, dựa trên labels.
* ports: Cấu hình cổng mà Service sẽ lắng nghe yêu cầu và cổng mà Pods sẽ sử dụng để xử lý các yêu cầu, ở đây đều là cổng 80.

## Apply file config vào github action để tiến hành deploy
Trong github workflow sẽ cần apply 2 file config mình vừa tạo ở bước trên để tiến hành deploy k8s, bạn thêm dòng này vào github workflow nha
```
- name: Apply Nginx Deployment
        run: |
          kubectl apply -f k8s/nginx-deployment.yaml
          kubectl apply -f k8s/nginx-service.yaml
```



-----


Như vậy đã xong quá trình deploy lên k8s sử dụng nodejs, các bạn có thắc mắc cứ comment bên dưới nha 🥰