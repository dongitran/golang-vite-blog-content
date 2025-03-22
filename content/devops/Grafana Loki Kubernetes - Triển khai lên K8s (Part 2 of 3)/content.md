Series Grafana Loki Kubernetes:
1. [Grafana Loki Kubernetes - Tìm hiểu cơ bản](https://viblo.asia/p/grafana-loki-kubernetes-tim-hieu-co-ban-part-13-PwlVm7jlJ5Z)
2. [Grafana Loki Kubernetes - Triển khai lên K8s](https://viblo.asia/p/grafana-loki-kubernetes-trien-khai-len-k8s-part-23-EoW4o3xo4ml)

Bài trước chúng ta đã tìm hiểu được cơ bản về grafana loki, promtail. Bây giờ mình triển khai lên k8s luôn nhé 😄

## 👽Tạo namespace
Trước tiên mình cần tạo namespace để dễ quản lý tài nguyên, mình đặt namespace tên monitoring nha.

Mình sẽ tạo file namespace.yaml:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
```
sau đó chạy lệnh **kubectl apply -f namespace.yaml** để tạo namespace
## 🚁 Deploy grafana dashboard
#### Tạo password đăng nhập vào grafana dashboard
Do mình muốn tạo password luôn nên tạo bằng secret bằng câu lệnh dưới luôn, bạn thay "admin" bằng password bạn muốn cấu hình nhé
```bash
kubectl create secret generic grafana-secret --from-literal=admin-password=admin --namespace=monitoring
```

Sau đó apply code bên dưới để grafana, khi chạy xong thì các bạn có thể access vào `http://{nodePortIP}:31005` sẽ ra dashboard của grafana nha, nhưng sẽ không có nguồn data nào được add vào nên chưa thể query log gì cả 😅
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: grafana
  namespace: monitoring
spec:
  serviceName: grafana
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
        - name: grafana
          image: grafana/grafana:latest
          ports:
            - containerPort: 3000
          env:
            - name: GF_SECURITY_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: grafana-secret
                  key: admin-password
          volumeMounts:
            - name: grafana-storage
              mountPath: /var/lib/grafana
      volumes:
        - name: grafana-storage
          emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: grafana-nodeport
  namespace: monitoring
spec:
  type: NodePort
  selector:
    app: grafana
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
      nodePort: 31005
```
## 🛸 Deploy grafana loki
Tiếp theo là apply file dưới để tạo loki để kết nối đến grafana và nhận dữ liệu từ promtail
```yaml
apiVersion: v1
kind: Service
metadata:
  name: loki
  namespace: monitoring
spec:
  selector:
    app: loki
  ports:
    - protocol: TCP
      port: 3100
      targetPort: 3100

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: loki
  namespace: monitoring
spec:
  serviceName: loki
  replicas: 1
  selector:
    matchLabels:
      app: loki
  template:
    metadata:
      labels:
        app: loki
    spec:
      containers:
      - name: loki
        image: docker.io/grafana/loki:2.9.6
        args:
          - -config.file=/etc/loki/local-config.yaml
        ports:
        - containerPort: 3100
        volumeMounts:
        - name: config-volume
          mountPath: /etc/loki
      volumes:
      - name: config-volume
        configMap:
          name: loki-config

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-config
  namespace: monitoring
data:
  local-config.yaml: |
    auth_enabled: false

    server:
      http_listen_port: 3100

    common:
      path_prefix: /loki
      storage:
        filesystem:
          chunks_directory: /loki/chunks
          rules_directory: /loki/rules
      replication_factor: 1
      ring:
        kvstore:
          store: inmemory

    schema_config:
      configs:
        - from: 2020-10-24
          store: boltdb-shipper
          object_store: filesystem
          schema: v11
          index:
            prefix: index_
            period: 24h

    ruler:
      alertmanager_url: http://localhost:9093
```
## 🚀 Deploy promtail
Cuối cùng mình apply thêm yaml dưới để tạo promtail để thu thập data từ các pod nhé
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: promtail-daemonset
  namespace: monitoring
spec:
  selector:
    matchLabels:
      name: promtail
  template:
    metadata:
      labels:
        name: promtail
    spec:
      serviceAccount: promtail-serviceaccount
      containers:
      - name: promtail-container
        image: grafana/promtail
        args:
        - -config.file=/etc/promtail/promtail.yaml
        env: 
        - name: 'HOSTNAME'
          valueFrom:
            fieldRef:
              fieldPath: 'spec.nodeName'
        volumeMounts:
        - name: logs
          mountPath: /var/log
        - name: promtail-config
          mountPath: /etc/promtail
        - mountPath: /var/lib/docker/containers
          name: varlibdockercontainers
          readOnly: true
      volumes:
      - name: logs
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: promtail-config
        configMap:
          name: promtail-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: promtail-config
  namespace: monitoring
data:
  promtail.yaml: |
    server:
      http_listen_port: 9080
      grpc_listen_port: 0

    clients:
    - url: http://loki:3100/loki/api/v1/push

    positions:
      filename: /tmp/positions.yaml
    target_config:
      sync_period: 10s
    scrape_configs:
    - job_name: pod-logs
      kubernetes_sd_configs:
        - role: pod
      pipeline_stages:
        - docker: {}
      relabel_configs:
        - source_labels:
            - __meta_kubernetes_pod_node_name
          target_label: __host__
        - action: labelmap
          regex: __meta_kubernetes_pod_label_(.+)
        - action: replace
          replacement: $1
          separator: /
          source_labels:
            - __meta_kubernetes_namespace
            - __meta_kubernetes_pod_name
          target_label: job
        - action: replace
          source_labels:
            - __meta_kubernetes_namespace
          target_label: namespace
        - action: replace
          source_labels:
            - __meta_kubernetes_pod_name
          target_label: pod
        - action: replace
          source_labels:
            - __meta_kubernetes_pod_container_name
          target_label: container
        - replacement: /var/log/pods/*$1/*.log
          separator: /
          source_labels:
            - __meta_kubernetes_pod_uid
            - __meta_kubernetes_pod_container_name
          target_label: __path__

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: promtail-clusterrole
  namespace: monitoring
rules:
  - apiGroups: [""]
    resources:
    - nodes
    - services
    - pods
    - pods/log
    - nodes/proxy
    verbs:
    - get
    - watch
    - list
    - get

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: promtail-serviceaccount
  namespace: monitoring

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: promtail-clusterrolebinding
  namespace: monitoring
subjects:
    - kind: ServiceAccount
      name: promtail-serviceaccount
      namespace: monitoring
roleRef:
    kind: ClusterRole
    name: promtail-clusterrole
    apiGroup: rbac.authorization.k8s.io
```

## 🎉️️️️️️ Demo thử nào
Như vậy là ta đã triển khai xong cả grafana dashboard, loki và promtail, giờ hãy truy cập vào dashboard `http://{nodePortIP}:31005`, sau đó tiến đến phần Connections -> Add new connection và thêm như sau và nhấn Save lại nhé
![](https://images.viblo.asia/729756fa-4643-4201-87ed-253fcf14f20e.png)

Sau đó bạn vào Explore và chọn vào datasource là Loki và query thử nhé
![](https://images.viblo.asia/1f711226-2de2-4672-8593-de9e36fd8dad.png)

---
Như vậy đã xong quá trình deploy lên k8s sử dụng nodejs, các bạn có thắc mắc cứ comment bên dưới nha 🥰