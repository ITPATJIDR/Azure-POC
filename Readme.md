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
      [ External World ]          [ Azure Cloud Ecosystem (VNet) ]
              |
      (1) User Traffic            +-----------------------------------------------------+
              |                   |  Azure Virtual Network (VNet)                       |
              v                   |                                                     |
      +---------------+           |   +---------------------------------------------+   |
      | Azure Public  |           |   |       Azure Kubernetes Service (AKS)        |   |
      | Load Balancer +----------->   |                                             |   |
      +---------------+           |   |  (Tier 1: Presentation)                     |   |
              |                   |   |  +-------------------+                      |   |
              |                   |   |  |   Frontend Pods   | (React/Vite)         |   |
              |                   |   |  +---------+---------+                      |   |
              |                   |   |            |                                |   |
              |                   |   |            v                                |   |
              |                   |   |  (Tier 2: Application)                      |   |
              |                   |   |  +-------------------+                      |   |
              |                   |   |  |    Backend Pods   | (Node.js API)        |   |
              |                   |   |  +---------+---------+                      |   |
              |                   |   +------------|--------------------------------+   |
              |                   |                |                                    |
              |                   |                | (Private Link / Managed Identity)  |
              |                   |                v                                    |
              |                   |   +---------------------------+                     |
              |                   |   |    (Tier 3: Data Tier)    |                     |
              |                   |   |   PostgreSQL (Flexible)   |                     |
              |                   |   +---------------------------+                     |
              |                   +-----------------------------------------------------+
              |                                     ^
              |           (Image Pull)              |
              +-------------------------------------+
                               |
                   +-----------------------+
                   | Azure Container Reg.  |
                   |        (ACR)          |
                   +-----------^-----------+
                               |
      [ CI/CD Pipeline ]       | (2) Docker Push
                               |
      +------------------------+------------------------+
      |             GitHub Actions (Runner)             |
      |  1. Build Docker      2. Push to ACR            |
      |  3. Helm Package      4. Deploy to AKS          |
      +------------------------^------------------------+
                               |
                        (3) Git Push
                               |
                        +--------------+
                        |  Developer   |
                        +--------------+

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

- test
- build and push
- deploy


### Monitoring and logging setup
- prometheus
- grafana
- loki
- promtail

### Explan Code 
- frontend 
- backend 
- database
- k8s
- opentofu 
- docker-compose
