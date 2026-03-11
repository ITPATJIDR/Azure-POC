# How to deploy the project
อันดับเเรกที่ต้องทำเลย ก็คือ git clone
```
	git clone https://github.com/ITPATJIDR/Azure-POC.git
```

จากนั้น ติดตั้ง azure cli เเละ opentofu
```
	sudo apt-get update && sudo apt-get install -y azure-cli opentofu
```

ต่อไปจะต้อง setup credentials ของ azure ที่ใช้สำหรับ opentofu 
- เริ่มจาก login azure 
```
	az login
```
- ต่อเราจะต้อง ดึง subscription id ออกมาเพื่อใช้สร้าง Service Principal 
```
	az account show --query id -o tsv
	az ad sp create-for-rbac --name {CHANGEME} --role Contributor --scopes /subscriptions/{CHANGEME}
```
- จากนั้นเอา output จาก ข้อก่อนหน้ามาใส่ในไฟล์ในไฟล์ opentofu/az.json
```
{
  "appId": "YOUR_CLIENT_ID",
  "displayName": "opentofu-sp",
  "password": "YOUR_CLIENT_SECRET",
  "tenant": "YOUR_TENANT_ID",
  "subscriptionId": "SUBSCRIPTION_ID"
}
```

สร้าง terraform.tfvars สำหรับ opentofu
```
ตัวอย่างไฟล์ /opentofu/terraform.tfvars

# ── Project ───────────────────────────────────────────────────────────────────
project_name        = PROJECT_NAME
environment         = ENVIRONMENT
location            = LOCATION
resource_group_name = RESOURCE_GROUP_NAME 

# ── AKS ───────────────────────────────────────────────────────────────────────
aks_system_vm_size    = VM_Size
aks_system_node_count = System Node Count 
aks_user_vm_size      = User_VM_Size
aks_user_node_count   = User Node Count 
aks_admin_username    = admin username

ssh_public_key = "ssh-rsa public_key"

# ── Database ──────────────────────────────────────────────────────────────────
db_admin_login = Database Admin Login
db_sku_name    = Database SKU
db_storage_mb  = Database Storage

db_admin_password = Database Password
```

จากนั้นเริ่มจาก infrastructure ด้วย opentofu ได้เลย 
```
	cd opentofu
	tofu init
	tofu plan
	make apply 
```

จากนั้นให้ทำการ push ของขึ้นไปที่ Github ของตัวเองจากนั้นเราจะ setup github actions secret กัน
- ไปที่ repository ของตัวเอง จากนั้น settings เเละ ไปที่ secrets and variables เข้าไปที่ เมนู actions กด new repository secret

- Secret เเรก ชื่อ AZURE_CREDENTIALS 
```
{
  "appId": "YOUR_CLIENT_ID",
  "displayName": "opentofu-sp",
  "password": "YOUR_CLIENT_SECRET",
  "tenant": "YOUR_TENANT_ID",
  "subscriptionId": "SUBSCRIPTION_ID"
}
```

- Secret ที่สอง ชื่อ DB_PASSWORD ตั้งรหัสผ่านของ Database 

ต่อไป หลังจากที่ opentofu สร้าง infrastructure เสร็จเเล้ว เราจะทำการ push code ขึ้นไปที่ Github ของตัวเองเพื่อให้ git action ทำการ deploy frontend เเละ backend ให้
```
	git push
```
---


# Architecture and CI/CD diagrams

### โปรเจคนี้สร้างขึ้นบน three tier architecture 
```
╔══════════════════════════════════════════════════════════════════════════════════════════════════════╗
║                           TASKFLOW — THREE-TIER INFRASTRUCTURE (Azure / South East Asia)             ║
╚══════════════════════════════════════════════════════════════════════════════════════════════════════╝

  [ DEVELOPER ]              [ GitHub Actions — CI/CD Pipeline ]
      │                       ┌────────────────────────────────────────────────┐
      │  git push             │  1. Run Tests (Vitest / Jest)                  │
      └──────────────────────>│  2. Docker Build & Push ──────────────────────────────────┐
                              │  3. helm upgrade --install taskflow            │          │
                              └──────────────────────────┬─────────────────────┘          │
                                                         │ kubectl/helm                   │ docker push
                                                         │                                │
══════════════════════════════════════════════════════╤══╪═════════════════════════════╤══╪════════════╗
 Azure Cloud  (southeastasia / Resource Group:        │  │                             │  │            ║
              scg-dev-rg)                             │  │                             │  ▼            ║
                                                      │  │                  ┌─────────────────────┐    ║
                                                      │  │                  │  Azure Container    │    ║
  ┌───────────────────────────────────────────────────┼──┼──────────────┐   │  Registry (ACR)     │    ║
  │  VNet: scg-dev-vnet  (10.0.0.0/16)                │  │              │   │  scgdevacr          │    ║
  │                                                   │  │  image pull  │   │  10.0.3.0/24        │    ║
  │  ┌──────────────────────────────────────────────┐ │◄─┼──────────────┘   │  (Private Endpoint) │    ║
  │  │  Azure Kubernetes Service (scg-dev-aks)       │ │  │  :443           └─────────────────────┘    ║
  │  │  Standard Tier · Azure CNI · Zones: 2,3       │ │  │                                            ║
  │  │                                               │ │  │                                            ║
  │  │  ┌──────────────────────────────────────────┐ │ │  │                                            ║
  │  │  │  System Node Pool (10.0.1.0/24)          │ │ │  │                                             ║
  │  │  │  Standard_D2s_v3 · 1 node                │ │ │  │                                             ║
  │  │  │  [only_critical_addons]                  │ │ │  │                                             ║
  │  │  │                                          │ │ │  │                                             ║
  │  │  │  ┌────────────────────────────────────┐  │ │ │  │                                             ║
  │  │  │  │  NGINX Ingress Controller            │  │ │ │  │                                            ║
  │  │  │  │  (Azure Public Load Balancer)         │◄──┘  │                                            ║
  │  │  │  │  HTTP :80 → redirect HTTPS           │  │    │   NSG: Allow :80,:443,:30000-32767         ║
  │  │  │  │  HTTPS :443 (TLS via cert-manager)   │  │    │        Allow VNet, AzureLB                ║
  │  │  │  └──────────────┬──────────────────────┘  │    │        Deny All others                    ║
  │  │  │                 │                          │    │                                            ║
  │  │  │           Ingress Rules                    │    │                                            ║
  │  │  │     path:/  ──────────────────────┐        │    │                                            ║
  │  │  │     path:/api ──────────────────┐ │        │    │                                            ║
  │  │  └──────────────────────────────── │─│────────┘    │                                            ║
  │  │                                    │ │              │                                            ║
  │  │  ┌──────────────────────────────── │─┼──────────────────────────────────────────────────────┐  ║
  │  │  │  User Node Pool (10.0.2.0/24)   │ │   Standard_D2s_v3 · 1 node                           │  ║
  │  │  │                                 │ │                                                       │  ║
  │  │  │  ┌──────────────────────────────┘ │                                                       │  ║
  │  │  │  │                                │                                                       │  ║
  │  │  │  │  TIER 1 — Presentation         │                                                       │  ║
  │  │  │  ▼                                │                                                       │  ║
  │  │  │  ┌──────────────────────────┐     │                                                       │  ║
  │  │  │  │  Frontend Pods           │     │                                                       │  ║
  │  │  │  │  React/Vite (Nginx)      │     │                                                       │  ║
  │  │  │  │  image: taskflow-frontend│     │                                                       │  ║
  │  │  │  │  cpu req: 50m / lim:100m │     │                                                       │  ║
  │  │  │  │  mem req: 64Mi/ lim:128Mi│     │                                                       │  ║
  │  │  │  │  ┌─────────────────────┐ │     │                                                       │  ║
  │  │  │  │  │ HPA: 2–5 pods       │ │     │                                                       │  ║
  │  │  │  │  │ target CPU: 70%     │ │     │                                                       │  ║
  │  │  │  │  └─────────────────────┘ │     │                                                       │  ║
  │  │  │  └──────────────────────────┘     │                                                       │  ║
  │  │  │                                   │                                                       │  ║
  │  │  │  TIER 2 — Application             │                                                       │  ║
  │  │  │  ▼                                │                                                       │  ║
  │  │  │  ┌──────────────────────────┐     │     ┌──────────────────────────────┐                  │  ║
  │  │  │  │  Backend Pods            │     │     │  Observability Stack          │                  │  ║
  │  │  │  │  Node.js API (Express)   │     │     │                              │                  │  ║
  │  │  │  │  image: taskflow-backend │     │     │  ┌──────────┐ ┌───────────┐  │                  │  ║
  │  │  │  │  cpu req:100m / lim:250m │     │     │  │Prometheus│ │  Grafana  │  │                  │  ║
  │  │  │  │  mem req:128Mi/ lim:256Mi│     │     │  └────┬─────┘ └─────▲─────┘  │                  │  ║
  │  │  │  │  PORT: 3001              │─────┼─────│───────┘             │        │                  │  ║
  │  │  │  │  /health (readiness)     │     │     │  ┌──────────┐ ┌──────────┐   │                  │  ║
  │  │  │  │  ┌─────────────────────┐ │     │     │  │  Loki    │ │Alertmgr  │   │                  │  ║
  │  │  │  │  │ HPA: 2–5 pods       │ │     │     │  └──────────┘ └──────────┘   │                  │  ║
  │  │  │  │  │ target CPU: 70%     │ │     │     │  ┌──────────┐               │                  │  ║
  │  │  │  │  └─────────────────────┘ │     │     │  │ Promtail │ (log scraper) │                  │  ║
  │  │  │  └──────────┬───────────────┘     │     │  └──────────┘               │                  │  ║
  │  │  │             │ :5432               │     │  (kube-prometheus-stack +    │                  │  ║
  │  │  └─────────────│─────────────────────┘     │   loki-stack Helm charts)   │                  │  ║
  │  │                │                           └──────────────────────────────┘                  │  ║
  │  └────────────────│─────────────────────────────────────────────────────────────────────────────┘  ║
  │                   │                                                                                 ║
  │  TIER 3 — Data    │ NSG: Allow :5432 from 10.0.1.0/24 & 10.0.2.0/24 only                          ║
  │                   │ Deny All Internet                                                              ║
  │                   ▼                                                                                ║
  │  ┌──────────────────────────────────────────────────────────────┐                                 ║
  │  │  PostgreSQL Flexible Server  (10.0.5.0/24)                   │                                 ║
  │  │  scg-dev-postgres.postgres.database.azure.com                │                                 ║
  │  │  SKU: B_Standard_B1ms · Storage: 32 GB · SSL: required       │                                 ║
  │  │  VNet Delegated: Microsoft.DBforPostgreSQL/flexibleServers    │                                 ║
  │  │  DB: tododb · User: todoadmin                                 │                                 ║
  │  └──────────────────────────────────────────────────────────────┘                                 ║
  │                                                                                                    ║
  │  ┌──────────────────────────┐                                                                     ║
  │  │  Management Subnet       │  ← SSH :22 (whitelist CIDR only)                                    ║
  │  │  10.0.4.0/24  [Bastion]  │    Deny All others                                                  ║
  │  └──────────────────────────┘                                                                     ║
  │                                                                                                    ║
  │  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐  ║
  │  │  Infrastructure-as-Code: OpenTofu modules                                                   │  ║
  │  │  modules/networking · modules/aks · modules/acr · modules/database · modules/loadbalancer   │  ║
  │  └─────────────────────────────────────────────────────────────────────────────────────────────┘  ║
  └────────────────────────────────────────────────────────────────────────────────────────────────────╝
                                                                                                       ║
╚══════════════════════════════════════════════════════════════════════════════════════════════════════╝

 LEGEND:
   ──► = Traffic flow / API call      :PORT = port number
   HPA = HorizontalPodAutoscaler      NSG  = Network Security Group
   CNI = Azure Container Network Interface (pod IP ∈ VNet)


```
โดยจุดประสงค์ ที่เลือก architecture นี้เพราะว่า เป็นพื้นฐานที่จะต่อยอดไปยัง architecture อื่นที่เป็นระดับ enterprise ได้เพราะว่าการเเบ่ง เป็น 3 layer ได้เเก่

- Presentation layer คือ layer สำหรับ รับ request จาก User เเละส่งข้อมูลไปยัง Application layer เพื่อ ประมวลผลต่อ

- Application layer คือส่วนที่ รับหน้าที่ ประมวลผลข้อมูลที่เข้ามา เเละ Read/Write ลง Database layer 

- Database layer คือส่วนที่ใช้เก็บข้อมูลต่างๆๆที่ได้จาก application layer เเละ ส่งข้อมูลต่างๆๆไปให้ application layer

เเละด้วยการออกเเบบ three tier architecture ทำให้เเต่ละ layer มีความ elastic สูงมาก เช่นเราสามารถ 

- scale เเค่ส่วน Application layer เพื่อรองรับ load ที่เพิ่มขึ้นมาได้ ถ้ากับ Kube เราก็ทำการติดตั้ง HPA เพื่อให้ scale pod ได้

---

### CI/CD pipeline
CI/CD จะทำงานเมือ มีการ push code ขึ้นไปบน project เเละ 

การทำ CI/CD จะเเบ่งเป็น 3 ขั้นตอนคือ 

- ## Test
	ข้างใน test pipeline จะประกอบด้วย 2 ขั้นตอน คือ 

	Test frontend โดยการ install dependency ที่ต้องใช้งานทั้งหมด เเละ รัน npm run test

	__test case__
	- เช็คว่ามี text "TaskFlow" อยุ่ในเว็บของเราหรือไม่ ถ้ามีก็จะผ่าน test

	---

	Test backend โดยการ install dependency ที่ต้องใช้งานทั้งหมด เเละ รัน npm run test

	__test case__
	- เช็คว่ามีการ เรียกใช้ app.* หรือป่าว ถ้ามีก็จะผ่าน test เพราะว่าคือการเรียกใช้ express

- ## Build and Push
	หลังจากที่ test ผ่านเเล้ว build and push pipe line ก็จะเริ่มต้นการทำงาน โดย
	- จะเริ่มจาก การ login ไปที่ Azure เเละ login ไปที่ ACR เพื่อให้มีสิทธิ์ในการ push image
	- ต่อมา ก็จะเริ่ม build image ด้วย buildX เริ่มจาก build frontend เเละ backend จากนั้น ติด tag เเละ ก็ส่งไปเก็บที่ registry

- ## Deploy
	หลังจากที่ build and push ผ่านเเล้ว deploy pipe line ก็จะเริ่มต้นการทำงาน โดย
	- จะ login เข้าไปที่ AKS เพื่อให้มีสิทธิ์ในการ deploy เเละต่อมาจะเริ่มต้นการ setup helm เเละสร้าง ACR Image Pull Secret เราจะได้มีสิทธ์ ในการ ดึง image มาจาก registry  

	- ต่อมา จะติดตั้ง Cert manager สำหรับจัดการ SSL certificate เเละติดตั้ง Monitoring and logging tool ต่างๆๆเช่น prometheus, grafana, loki, promtail

	- จากนั้น ก็สั่ง Helm upgrade ไปที่ k8s/helm/taskflow เพื่อให้ deploy ไปที่ AKS
	
	- หลังจาก upgrade เสร็จก็จะสั่ง Auto-seed database เพื่อให้ database พร้อมใช้งาน
	
### สามารถเข้าไปเล่นได้ที่ URL 

```
https://taskflow-scg.southeastasia.cloudapp.azure.com/
```



### Monitoring and logging setup
การติดตั้ง monitoring and logging tool ต่างๆๆเช่น prometheus, grafana, loki, promtail จะทำผ่าน helm chart โดย

จะมีไฟล์ /k8s/helm/taskflow/Chart.yaml โดยจะใช้ Community Chart kube-prometheus-stack เเละ loki-stack
```

...

dependencies:
  - name: kube-prometheus-stack
    version: "56.6.2" 
    repository: "https://prometheus-community.github.io/helm-charts"
    condition: kube-prometheus-stack.enabled
  
  ...

  - name: loki-stack
    version: "2.10.2"
    repository: "https://grafana.github.io/helm-charts"
    condition: loki-stack.enabled
```

เเละจะมีไฟล์ k8s/helm/taskflow/values.yaml สำหรับ config ค่าต่างๆๆ เช่น datasource, retention เเละ default rule

```
kube-prometheus-stack:
  enabled: true
  grafana:
    adminPassword: "admin" 
    additionalDataSources:
      - name: Loki
        type: loki
        url: http://taskflow-loki:3100
        access: proxy
        isDefault: false
  prometheus:
    prometheusSpec:
      retention: "5d"
  defaultRules:
    create: true
  alertmanager:
    enabled: true

loki-stack:
  enabled: true
  loki:
    isDefault: false
  promtail:
    enabled: true
```

