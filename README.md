# ⚙️ DevOps Interview Exercise

> **Scenario**  
> Your workload currently runs on Google Cloud:
> * **HTTP(S) Load Balancer** (global)
> * Backend Service → **Managed Instance Group (MIG)** built from an **Instance Template**
> * Each VM keeps a **stateful disk** and re-attaches the same **static external IP** at every boot
> * Public DNS is managed in **Cloudflare**
> * The containerised app connects to **Cloud SQL** and calls an external **LLM API**
> * Worker nodes have **NVIDIA L40** GPUs

Management now wants a **fully automated, zero-downtime path** to:

1. Re-create the entire stack from scratch (IaC + GitLab CI/CD)
2. Deploy application updates with *zero downtime* 🚀


## 📝 Candidate Task 1 – Design & Document

### 1️⃣ Architecture sketch & narrative

* Diagram or describe every GCP component (LB, backend service, MIG, Cloud SQL, NAT, Cloudflare, etc.).
* Explain data-plane flow, health checks, and network security.
* Identify key IAM roles / service accounts.
* Where does TLS termination occur?

### 2️⃣ GPU software requirements

* Which host-level software / drivers are required for an **NVIDIA L40**?
* How does the container access the GPU (driver vs. runtime vs. libraries)? 🎮

### 3️⃣ GitLab CI/CD pipeline outline

* List the high-level stages and approval gates.
* Show where artefacts / images are stored and **how the pipeline authenticates to GCP** 🔐.

### 4️⃣ Zero-downtime update strategy

* Choose **rolling update** *or* **blue/green** and justify.
* Detail health-check behaviour (`maxSurge`, `maxUnavailable`) *or* traffic-splitting and rollback.
* Explain how the stateful disk and static IP are preserved during updates.

> **Format** – Whiteboard, screen-share a diagram tool, or commit Markdown / diagrams-as-code.  
> Be ready to discuss trade-offs, failure modes, and rollback.

---

## 🛠️ Candidate Task 2 – Terraform IaC Bootstrap

A minimal **`terraform/`** directory is provided.

### Your tasks

1. Briefly explain what each existing file does.
2. Add **`providers.tf`** and **`main.tf`** that:
    * Configure the **Google Cloud provider**.
    * Use a **`container-on-mig`** module (or equivalent) to create a MIG that runs the container image 🏗️.