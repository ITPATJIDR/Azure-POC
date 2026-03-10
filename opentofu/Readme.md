### providers.tf
คือ ไฟล์ที่ใช้กำหนด cloud provider เเละ authentication ทำให้ tofu สามารถเข้าไป สร้าง resource ได้

### ACR
คือ module ที่ใช้สร้าง Azure Container Registry เเละ Private Endpoint เเละ Private DNS Zone

module นี้จะใช้ SKU เเบบ Premium เพื่อจะใช้งาน Private Link เวลา Aks จะมาดึง Docker image ก้จะวิ่งเข้ามาผ่าน Internal IP เลยไม่ต้องออกเน็ต 

### AKS
คือ module ที่ใช้สร้าง Azure Kubernetes Service เเละ Log Analytics Workspace 

โดยใน AKS จะเเบ่ง เป็น 2 Node Pool คือ 
- System Node Pool : ที่จะเป็นพื่นที่สำหรับ components ของ Kube เท่านั้น 
- User Node Pool : ที่จะเป็นพื่นที่สำหรับ Application ของเรา 

โดยจะกำหนดผ่านการเเยก subnet เเละกระจายเครื่องไปอยุ่ ระหว่าง Zone 2,3 ของ region

### Database 
คือ module ที่ใช้สร้าง Azure Database for PostgreSQL เเละ Private Endpoint เเละ Private DNS Zone เพื่อให้มีเเค่ application เท่านั้นที่สามารถเชื่อมต่อ Database ได้ 

โดยจะมีการกำหนด ให้ ไม่สามารถเข้าผ่าน public network ได้ เเละ ตั้งเวลา rententionไว้ที่ ตี 2 ของทุกวัน เเละวาง Database ไว้ใน subnet ที่กำหนดไว้ เเละ ตั้ง Zone ไว้ที่ Zone 1 เพราะว่า เป็น POC เลยเเละมี Cost ที่จำกัดเลย เลือกตั้งไว้ที่ Zone เดียวก่อน

### Loadbalancer 
คือ module ที่ใช้สร้าง Azure Load Balancer เเละ Public IP เเละ Outbound Rule 

โดย LB จะวางอยุ่ที่ 3 Zone เลย เพราะว่ามีความเป็น HA สูง เเละมีการกำหนด inbound ให้มีเเค่ port 80 เเละ 443 

### Networking 
คือ module ที่ใช้สร้าง Vnet เเละ Subnet เเละ NSG

subnet ที่จะสร้างก็จะมี 
- 10.0.1.0/24 
- 10.0.2.0/24 
- 10.0.3.0/24 
- 10.0.4.0/24 
- 10.0.5.0/24 

## Security Groups (NSG) 

โดยของ AKS
#### inbound 
- 80 & 443 สำหรับ traffic ขาเข้า
- 30000-32767 สำหรับส่ง traffic ไป Node port ด้านหลัง
- ทุก port ของ VirtualNetwork เพื่อให้เครื่อง Nodes คุยกันเองได้
- ทุก port จาก AzureLoadBalancer เพื่อให้ตัว LB สามารถส่ง Probe มาเช็กสุขภาพเครื่องได้

#### outbound 
- 443-9000 สำหรับส่งข้อมูล AKS API Server 
- 5432 สำหรับ postgres

โดย Database 
#### inbound
- 5432 เปิดรับเฉพาะ AKS subnets เเละ Management Subnet 

โดย Management 
#### inbound
- 22 & 3389 เปิดรับเฉพาะจาก IP ที่ระบุไว้ (Whitelisted CIDR) เท่านั้น เพื่อใช้สำหรับแอดมิน


## Main.tf
เป็นไฟล์หลักที่ใช้สร้าง Infrastructure ทั้งหมด คือ AKS ACR Postgres LB Vnet Subnet 









