# One-click Grafana + VictoriaMetrics on AWS

**One command builds everything:** the AWS network, firewalls, servers and load balancer
(Terraform), then installs the monitoring software (Ansible).

```bash
./deploy.sh      # build everything (~10 min), prints the Grafana link
./destroy.sh     # delete everything
```

Or run Jenkins: **Build with Parameters → apply**.

The diagram is in `architecture.png`.

---

## 1. What's in this folder (everything in one place)

| File | What it does | Diagram part |
|---|---|---|
| `deploy.sh` | **The one click**: runs Terraform, which also runs Ansible | – |
| `destroy.sh` | Deletes everything | – |
| `Jenkinsfile` | Same one click, from Jenkins | Jenkins |
| `terraform.tfvars` | **Your values** (change 3 lines) | – |
| `provider.tf` | Use AWS in Mumbai | Mumbai (ap-south-1) |
| `variables.tf` | The inputs | – |
| `vpc.tf` | VPC, 4 subnets, Internet Gateway, NAT, route tables, NACLs | VPC, subnets, IGW, NAT, RT, NACL |
| `security_groups.tf` | Firewalls | alb-sg, bastion-sg, monitoring-sg |
| `ec2.tf` | 3 servers | Bastion host, monitoring-a, monitoring-b |
| `alb.tf` | Load balancer + target group | ALB, Target group Grafana :3000 |
| `ansible.tf` | Writes the server list and **starts Ansible automatically** | Terraform → Ansible |
| `playbook.yml` | Installs the 4 programs on both servers | node_exporter, vmagent, VictoriaMetrics, Grafana |
| `ansible.cfg` | Ansible settings | – |
| `outputs.tf` | Prints the Grafana link | – |
| `inventory.ini` | *Created automatically* (server IPs for Ansible) | – |

## 2. How the one click works

```
./deploy.sh  (or Jenkins)
   └─ terraform apply
        ├─ builds VPC, subnets, NAT, firewalls, 3 EC2s, ALB      (vpc.tf, ec2.tf, alb.tf ...)
        ├─ writes inventory.ini with the server IPs              (ansible.tf)
        └─ runs ansible-playbook playbook.yml                    (ansible.tf)
              └─ installs node_exporter → VictoriaMetrics → vmagent → Grafana on both servers
```

## 3. Setup (one time, on your laptop)

1. **Install:** Terraform (1.4 or newer), Ansible, AWS CLI.
   Mac: `brew install terraform ansible awscli`
2. **AWS login:** `aws configure` (paste your access key and secret key, region `ap-south-1`).
3. **Key pair:** EC2 console (Mumbai) → Key pairs → Create → download the `.pem`, then:
   ```bash
   mv ~/Downloads/my-key.pem ~/.ssh/ && chmod 400 ~/.ssh/my-key.pem
   ```
4. **Edit `terraform.tfvars`:**
   - `my_ip`: run `curl ifconfig.me`, add `/32` (example `49.36.10.20/32`)
   - `key_name`: your key pair's name
   - `private_key_path`: path to the `.pem`
5. Run:
   ```bash
   chmod +x deploy.sh destroy.sh
   ./deploy.sh
   ```

## 4. Check it works

1. Open the printed link and log in: user `admin`, password `Admin@123` (set at the top of `playbook.yml`).
2. **Explore** → choose **VictoriaMetrics** → type `node_load1` → **Run query** → you'll see one line per server.
3. Optional: **Dashboards → New → Import** → ID `1860` → choose VictoriaMetrics.

**Show high availability:** stop `monitoring-a` in the EC2 console, wait about 1 minute, refresh Grafana.
It still works. (You may need to log in again.)

## 5. Jenkins (optional)

1. On the Jenkins machine install Terraform, Ansible, and the plugins Pipeline, Git and Credentials Binding.
2. Manage Jenkins → Credentials → add 2 **Secret text** items: `aws-access-key-id`, `aws-secret-access-key`.
3. Put the `.pem` file on the Jenkins machine (readable by the `jenkins` user) and set its path in `terraform.tfvars`.
4. Push this folder to GitHub → New **Pipeline** job → "Pipeline script from SCM" → your repo.
5. **Build with Parameters → apply**. To delete: **destroy** (in the same job).

---

## 6. Explain it to your teacher

**In one line:** "One click builds a monitoring system on AWS that shows my servers' CPU,
memory and disk in Grafana. It keeps working even if one data center goes down."

**The 3 tools:**

| Tool | Job | Like... |
|---|---|---|
| Terraform | Creates the AWS resources | the **builder** of the house |
| Ansible | Installs the software inside the servers | the **electrician** |
| Jenkins | Starts everything with one click | the **manager** |

**The 4 programs on each server:**
*node_exporter measures → vmagent collects (every 15 s, from **both** servers) → VictoriaMetrics stores → Grafana shows.*

**The diagram in short:**
- 2 AZs = 2 separate data centers in Mumbai.
- **Public subnets** (10.0.1.0/24, 10.0.2.0/24): load balancer and bastion host. The internet can reach these.
- **Private subnets** (10.0.11.0/24, 10.0.12.0/24): the 2 monitoring servers, with no public IP (safe).
- **Internet Gateway** = the VPC's door to the internet. **NAT Gateway** = lets private servers download software, but nothing can come in through it.
- **Route tables** = road signs. **NACLs and security groups** = firewalls.
- **ALB + target group** = one link for users, which goes to a healthy Grafana.
- **Bastion** = jump server. Ansible goes through it to reach the private servers.

**Why it's highly available:** 2 identical servers in 2 AZs, each with the full data (each vmagent
collects from both). The load balancer only sends users to healthy servers.

**Teacher's questions:**
- *Why both Terraform and Ansible?* Terraform creates cloud resources; Ansible configures what runs inside the servers.
- *How is it one click?* `ansible.tf` tells Terraform to run Ansible as soon as the servers are ready.
- *Why private subnets?* Security: no public IP, so nobody on the internet can reach the servers directly.
- *What's a target group?* The list of servers the load balancer sends users to (Grafana :3000 on both servers).

---

## 7. Common problems

| Problem | Fix |
|---|---|
| No credentials / `UnauthorizedOperation` | Run `aws configure` again |
| `InvalidKeyPair.NotFound` | The key pair must be in **ap-south-1** and match `key_name` |
| `Permission denied (publickey)` | Check `private_key_path`; run `chmod 400` on the `.pem` |
| Ansible can't reach the bastion | Your IP changed: update `my_ip` and run `./deploy.sh` again |
| Ansible step failed halfway | Just run `./deploy.sh` again; it continues |
| Grafana link shows 502 / 503 | Grafana is still starting. Wait 1–2 minutes |

**After the demo, always run `./destroy.sh`.** The NAT Gateway and the load balancer cost money every hour.

*Kept simple on purpose:* NACLs are open (security groups do the filtering), there's only one NAT Gateway,
Terraform state stays on your laptop, and Grafana uses plain HTTP.
