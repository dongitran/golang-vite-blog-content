Series PostgreSQL Replication:
1. [PostgreSQL Replication - Tổng quan và cơ chế hoạt động](https://viblo.asia/p/postgresql-replication-tong-quan-va-co-che-hoat-dong-part-12-GAWVpyxo405)
2. [PostgreSQL Replication - Triển khai lên K8s](https://viblo.asia/p/grafana-loki-kubernetes-trien-khai-len-k8s-part-23-EoW4o3xo4ml)
3. [PostgreSQL Replication - Xây dựng CI-CD để deploy tự động](https://viblo.asia/p/postgresql-replication-xay-dung-ci-cd-de-deploy-tu-dong-part-23-y37LdvE04ov)

![](https://images.viblo.asia/addd52e2-4dd5-4a7e-886f-8a5255dd6da1.png)

Bài trước mình đã đi sơ lược về postgres replication, bài này mình sẽ bắt tay vào deploy thử lên k8s luôn nhé 😆

# Namespace
Để dễ quản lý resource trên k8s, thì mình sẽ tạo namespace postgresql-replication cho tất cả tài nguyên tạo ra của postgresql
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: postgresql-replication
```

# Config map để cấu hình postgresql
Tạo config map sẽ lưu các file cấu hình thông số replication và các cấu hình kết nối
### Tạo các file cấu hình
Tạo file postgres.config để cấu hình cho cả master và slave
```yaml
# -----------------------------
# PostgreSQL configuration file
# -----------------------------

listen_addresses = '*'
max_connections = 100
shared_buffers = 128MB
dynamic_shared_memory_type = posix
log_timezone = 'UTC'
datestyle = 'iso, mdy'
timezone = 'UTC'
lc_messages = 'en_US.utf8'			# locale for system error message
lc_monetary = 'en_US.utf8'			# locale for monetary formatting
lc_numeric = 'en_US.utf8'			# locale for number formatting
lc_time = 'en_US.utf8'				# locale for time formatting
default_text_search_config = 'pg_catalog.english'

#------------------------------------------------------------------------------
# CUSTOMIZED OPTIONS
#------------------------------------------------------------------------------

# Add settings for extensions here
include_if_exists = 'master.conf'
include_if_exists = 'slave.conf'
```

Tạo file master.conf để cấu hình riêng cho master
```yaml
wal_level = replica
max_wal_senders = 5
max_replication_slots = 5
synchronous_commit = off
```

Tạo file slave.conf để cấu hình cho slave
```yaml
hot_standby = on
wal_level = replica
max_wal_senders = 5
max_replication_slots = 5
synchronous_commit = off
```

Tạo file pg_hpa
```yaml
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust

host    replication     replication     all                     md5
host    all             all             all                     md5
```

### Script để tạo/cập nhật config map 
Tạo file create_configmap.sh như sau
```bash
#!/bin/bash

CONFIGMAP_NAME="postgresql-replication-configmap"
NAMESPACE="postgresql-replication"

if kubectl get configmap $CONFIGMAP_NAME -n $NAMESPACE &> /dev/null; then
    kubectl delete configmap $CONFIGMAP_NAME -n $NAMESPACE
    echo "Deleted ConfigMap $CONFIGMAP_NAME"
fi

kubectl create configmap $CONFIGMAP_NAME --from-file=./config/postgres.conf --from-file=./config/master.conf --from-file=./config/slave.conf --from-file=./config/pg_hba.conf --from-file=./config/create-slave-user.sh -n $NAMESPACE
echo "Created ConfigMap $CONFIGMAP_NAME successful"
```
Sau đó chạy lệnh sau để chạy script và tạo config map nhé
```bash
./config/create_configmap.sh
```

# Secret 
Tạo secret để lưu password của khi kết nối đến postgres và password để slave kết nôi đến master

secret.yaml:
```
apiVersion: v1
kind: Secret
metadata:
  name: postgresql-replication-secret
  namespace: postgresql-replication
type: Opaque
stringData:
  password: password
  replicaPassword: password
```
 Sau đó chạy lệnh `kubectl apply -f secret.yaml` để tạo secret

# Deploy master
Tạo service và satefulset master

master.yaml:
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: postgresql-replication-master-service
  name: postgresql-replication-master-service
  namespace: postgresql-replication
spec:
  type: NodePort 
  ports:
  - name: postgresql-replication-master-service
    port: 5432
    protocol: TCP
    targetPort: 5432
    nodePort: 30032
  selector:
    app: postgresql-replication-master

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql-replication-master
  namespace: postgresql-replication
spec:
  updateStrategy:
    type: RollingUpdate
  
  selector:
    matchLabels:
      app: postgresql-replication-master

  serviceName: postgresql-replication-master
  replicas: 1
  template:
    metadata:
      labels:
        app: postgresql-replication-master 
    spec:
      volumes:
        - name: postgres-config
          configMap:
            name: postgresql-replication-configmap
            
      terminationGracePeriodSeconds: 10

      containers:
        - name: postgres
          image: postgres:14
          args: ['-c', 'config_file=/etc/postgres.conf', '-c', 'hba_file=/etc/pg_hba.conf']
          
          imagePullPolicy: IfNotPresent
        
          ports:
            - name: postgres
              containerPort: 5432
              protocol: TCP
          
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
          
          env:
            - name: POSTGRES_USER
              value: postgres
          
            - name: PGUSER
              value: postgres
          
            - name: POSTGRES_DB
              value: postgres
            
            - name: PGDATA
              value: /var/lib/postgresql/14/main
          
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: password
                  name: postgresql-replication-secret
                  
            - name: REPLICATION_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: replicaPassword
                  name: postgresql-replication-secret
              
            - name: POD_IP
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: status.podIP
              
          livenessProbe:
            exec:
              command:
                - sh
                - -c
                - exec pg_isready --host $POD_IP
            failureThreshold: 6
            initialDelaySeconds: 60
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 5

          readinessProbe:
            exec:
              command:
                - sh
                - -c
                - exec pg_isready --host $POD_IP
            failureThreshold: 3
            initialDelaySeconds: 5
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 3

          volumeMounts:
            - mountPath: /var/lib/postgresql/14/main
              name: postgresql-replication-master-pvc
              subPath: postgres-db
              
            - name: postgres-config
              mountPath: /etc/postgres.conf
              subPath: postgres.conf
              
            - name: postgres-config
              mountPath: /etc/master.conf
              subPath: master.conf
              
            - name: postgres-config
              mountPath: /etc/pg_hba.conf
              subPath: pg_hba.conf
              
            - name: postgres-config
              mountPath: /docker-entrypoint-initdb.d/create-slave-user.sh
              subPath: create-slave-user.sh
          
  volumeClaimTemplates:
  - metadata:
      name: postgresql-replication-master-pvc
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```
 Sau đó chạy lệnh `kubectl apply -f master.yaml` để tạo master pod nhé, phải đợi khi nào pod master tạo xong và đã running thì mới làm bước tiếp theo nha

# Deploy slave
Sau khi chạy tạo master xong, mình tiếp tục tạo slave.yaml để tạo service và 1 pod slave

slave.yaml:
```
apiVersion: v1
kind: Service
metadata:
  labels:
    app: postgresql-replication-slave-service
  name: postgresql-replication-slave-service
  namespace: postgresql-replication
spec:
  type: NodePort
  ports:
  - name: postgresql-replication-slave-service
    port: 5432
    protocol: TCP
    targetPort: 5432
    nodePort: 30033
  selector:
    app: postgresql-replication-slave

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql-replication-slave
  namespace: postgresql-replication
spec:
  updateStrategy:
    type: RollingUpdate
  
  selector:
    matchLabels:
      app: postgresql-replication-slave

  serviceName: postgresql-replication-slave
  replicas: 1
  template:
    metadata:
      labels:
        app: postgresql-replication-slave
    spec:
      volumes:
        - name: postgres-config
          configMap:
            name: postgresql-replication-configmap
            
      terminationGracePeriodSeconds: 10
      
      initContainers:
        - name: setup-replica-data-directory
          image: postgres:14
          
          env:
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  key: replicaPassword
                  name: postgresql-replication-secret

          command:
          - sh
          - -c
          - |
            if [ -z "$(ls -A /var/lib/postgresql/14/main)" ]; then
                echo "Running pg_basebackup to catch up replication server...";
                pg_basebackup -h postgresql-replication-master-service -D /var/lib/postgresql/14/main -U replication -P -v -R -X stream -C -S slave_1
                chown -R postgres:postgres $PGDATA;
            else
                echo "Skipping pg_basebackup because directory is not empty"; 
            fi

          volumeMounts:
            - mountPath: /var/lib/postgresql/14/main
              name: postgresql-replication-slave-pvc
              subPath: postgres-db

      containers:
        - name: postgresql-replication-slave
          image: postgres:14
          args: ['-c', 'config_file=/etc/postgres.conf']
          
          imagePullPolicy: IfNotPresent
        
          ports:
            - name: postgres-rep
              containerPort: 5432
              protocol: TCP
          
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
          
          env:
            - name: POSTGRES_USER
              value: postgres
          
            - name: PGUSER
              value: postgres
          
            - name: POSTGRES_DB
              value: postgres
            
            - name: PGDATA
              value: /var/lib/postgresql/14/main
          
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: password
                  name: postgresql-replication-secret
              
            - name: POD_IP
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: status.podIP
              
          livenessProbe:
            exec:
              command:
                - sh
                - -c
                - exec pg_isready --host $POD_IP
            failureThreshold: 6
            initialDelaySeconds: 60
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 5

          readinessProbe:
            exec:
              command:
                - sh
                - -c
                - exec pg_isready --host $POD_IP
            failureThreshold: 3
            initialDelaySeconds: 5
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 3

          volumeMounts:
            - mountPath: /var/lib/postgresql/14/main
              name: postgresql-replication-slave-pvc
              subPath: postgres-db
            
            - name: postgres-config
              mountPath: /etc/postgres.conf
              subPath: postgres.conf

            - name: postgres-config
              mountPath: /etc/replica.conf
              subPath: replica.conf
            
      
          
  volumeClaimTemplates:
  - metadata:
      name: postgresql-replication-slave-pvc
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```
 Sau đó chạy lệnh `kubectl apply -f slave.yaml` để tạo pod slave nhé

# Kiểm tra hoạt động của postgresql replication
Chạy lệnh `kubectl get all -n postgresql-replication` để kiểm tra hoạt động các pod đã `Running` hết chưa nha 
![](https://images.viblo.asia/db28ce55-ceef-4598-8874-0f8c9a2c6177.png)

Nếu các pod không lỗi gì thì mình connect đến postgresql master và chạy sql `SELECT * FROM pg_stat_replication;` để kiểm tra slave đã kết nối đồng bộ dữ liệu chưa nhé, nếu hiển thị như bên dưới thì ok rồi nha
![](https://images.viblo.asia/e1250249-6f68-4095-bf35-ab0bf371add9.png)

Giờ mình thử tạo 1 table và insert data vào postgresql master:
```sql
CREATE TABLE DanhSachSinhVien (
    ID SERIAL PRIMARY KEY,
    HoTen VARCHAR(100),
    Tuoi INT,
    DiaChi VARCHAR(255)
);

INSERT INTO DanhSachSinhVien (HoTen, Tuoi, DiaChi)
VALUES ('Nguyen Van A', 20, '123 Đường ABC, Thành phố XYZ'),
       ('Tran Thi B', 22, '456 Đường DEF, Thành phố UVW');
```

Sau đó mình connect đến postgres slave và query data
```sql
select * from DanhSachSinhVien1;
```
Thì sẽ thấy data mình đã insert ở bên master nhé 🥰

Như vậy là mình đã triển khai được postgresql replication gồm 1 master và 1 slave, bài sau chúng ta sẽ triển khai quá trình CI-CD sử dung Github Action để tự động hoá việc tạo/cập nhật database nhé 😃

---
Series PostgreSQL Replication:
1. [PostgreSQL Replication - Tổng quan và cơ chế hoạt động](https://viblo.asia/p/postgresql-replication-tong-quan-va-co-che-hoat-dong-part-12-GAWVpyxo405)
2. [PostgreSQL Replication - Triển khai lên K8s](https://viblo.asia/p/grafana-loki-kubernetes-trien-khai-len-k8s-part-23-EoW4o3xo4ml)
3. [PostgreSQL Replication - Xây dựng CI-CD để deploy tự động](https://viblo.asia/p/postgresql-replication-xay-dung-ci-cd-de-deploy-tu-dong-part-23-y37LdvE04ov)