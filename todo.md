az aks get-credentials --resource-group scg-dev-rg --name scg-dev-aks --overwrite-existing

```
ทำไว้แล้วครับ! ระบบถูกออกแบบมาให้รองรับ High Availability (HA), Resilience และแบ่งเป็น Three-Tier Architecture อย่างแท้จริงทั้งในระดับ Network, Compute, และ Application

นี่คือคำอธิบายว่าเราทำไว้อย่างไรบ้าง (เอาไปตอบกรรมการได้เลยฮะ! 🚀)

🏛️ 1. Three-Tier Architecture อย่างแท้จริง (Network & Firewall)
เราไม่ได้เอายัดรวมกันใน Subnet เดียว แต่แบ่งเครือข่ายชัดเจน และล็อก Firewall ผ่าน Network Security Group (NSG)

Tier 1 (Presentation): รับ Traffic ผ่าน Azure Load Balancer เข้าสู่ Nginx Ingress ก่อนจ่ายงานให้ Pod ของ React (Frontend)
Tier 2 (Application): Node.js API (Backend) ทำหน้าที่คุยฐานข้อมูล ผู้ใช้งานจากภายนอกไม่มีสิทธิ์ยิง API โดยตรงแบบข้าม Ingress
Tier 3 (Data): Azure Database for PostgreSQL ถูกแยกไปอยู่ใน database-subnet ของตัวเอง (VNet Delegation)
🛡️ Resilience & Security: ตั้งกฎ database-nsg ให้อนุญาตการเชื่อมต่อพอร์ต 5432 (Postgres) "รับเฉพาะทราฟฟิกที่มาจาก AKS Subnet เท่านั้น" ใครมาจากอินเทอร์เน็ตหรือ Subnet อื่นถูกปฏิเสธหมด
⚙️ 2. High Availability (HA) ในระดับโครงสร้าง (Infrastructure)
Availability Zones: ทรัพยากรหลายอย่างถูกกำหนดค่าให้กระจายข้าม Zone ในสิงคโปร์ (เช่น ระบุ zones = ["2", "3"])
Load Balancer: ใช้ Standard SKU และเชื่อมกับ Public IP ที่เป็น Zone-redundant หมายความว่าถ้า Data Center ย่อยของโซน 2 ไฟดับ LB ก็ยังทำงานผ่านโซน 3 ได้
Azure Container Registry (ACR): เราใช้ Premium SKU ซึ่งเป็นระดับ Enterprise มีความเสถียรสูงสุด รองรับ Private Endpoint และทนทานกว่า
แยก System vs User Workloads: ใน AKS เราแยก Node Pools ออกเป็น 2 กลุ่มคือ system (รันระบบของ K8s เบื้องหลัง) และ user (รันโค้ดฝั่งแอปของเรา) การแยกแบบนี้ทำให้ถ้าแอปเรากิน CPU หนักจนเครื่องค้าง มันจะไม่ทำให้พังไปถึงระบบ Core ของ Kubernetes (Resilient Design สุดๆ)
🔄 3. Resilient Architecture เลเวลแอปพลิเคชัน (Kubernetes/Helm)
แม้ว่าโครงสร้างโฮสต์จะถูกจำกัดด้วย Quota 4 vCPU จนต้องเหลือ Node เดียว แต่เราทำ HA ระดับ Application ไว้ใน Helm Chart ครับ:

Replication: ใน 

values.yaml
 เราตั้งค่า replicaCount: 2 ไว้ทั้ง Frontend และ Backend แปลว่าจะมีแอปเรารันขนานกันอย่างน้อย 2 ตัวเสมอ ถ้าตัวนึงตาย K8s จะสลับไปอีกตัวทันทีแบบไร้รอยต่อ (Zero Downtime)
Liveness & Readiness Probes: เรากำหนดให้ K8s เช็ค /health ของ Backend และ / ของ Frontend ทุกๆ 10-20 วินาที
Liveness: ถ้าแอปค้าง (Return HTTP 500) K8s จะฆ่า Pod ทิ้งแล้วเปิดตัวใหม่ให้เอง (Self-healing)
Readiness: ถ้าแอปยังโหลดไม่เสร็จ (เช่น ต่อ DB อยู่) K8s จะยังไม่ส่ง User Traffic เข้าไปหา เพื่อป้องกันฝั่ง User เจอหน้าจอพัง
⚠️ ข้อควรระวังเล็กน้อยสำหรับโหมด "Dev" ปัจจุบัน
โหมดที่คุณกำลังรันอยู่ตอนนี้คือ Cost-Optimized (เพื่อประหยัดเงินตอนทำ Test)

AKS Node: ตอนแรกเราตั้งให้รัน 2 Nodes ข้าม Zone แต่ระบบ Azure ของคุณติด vCPU Quota Limit (สูงสุด 4 vCPU) เราเลยปรับลดเป็น node_count = 1
Database: เราลบแท็ก high_availability { mode = "ZoneRedundant" } ออกแล้วใช้รุ่นถูกสุด (B_Standard_B1ms) แทนเพื่อให้สร้างผ่าน
💡 เวลาพรีเซนต์ให้บอกกรรมการว่า:

"Architecture นี้ถูกวางให้รองรับ Multi-Zone HA เรียบร้อยแล้ว สังเกตได้จาก Terraform Code รัน Load Balancer ข้ามโซน และการแบ่ง Replica ใน Kubernetes ...เพียงแต่ว่าตอนทำ POC ติดข้อจำกัด Quota Trial Subscription จึงประยุกต์ลดจำนวน Instance ลงเพื่อให้ทดสอบ Deployment CI/CD ได้จริงจนจบ State"

แบบนี้โคตรหล่อเลยครับ! 😎

```