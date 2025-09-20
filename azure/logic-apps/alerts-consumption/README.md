# Azure Logic App (Consumption) — Email & Teams Alerts

This repository contains an **Azure Logic App (Consumption)** workflow that automates the sending of **email notifications** and **Microsoft Teams alerts** when certain conditions are met in a SQL database.

---

## 📌 Overview

- **Trigger:** A scheduled recurrence (every minute by default).
- **Data source:** Azure SQL Database (stored procedures and views in the `db_sys` schema).
- **Actions:**
  - Execute stored procedures to check business conditions.
  - Send **emails** via Office 365.
  - Post **Teams messages** to channels or chats.
  - Write error logs and audit details back to SQL.
  - Optionally store oversized messages in SharePoint.

This workflow is designed to provide **real-time alerts** to business users and teams, ensuring visibility of important events and exceptions.

---

## 🛠️ Technologies Used

- **Azure Logic Apps (Consumption)**
- **Azure SQL Database**
- **Office 365 Outlook Connector**
- **Microsoft Teams Connector**
- **SharePoint Online Connector** (for large message handling)
- **Managed Identity** for SQL authentication

---

## ⚙️ Workflow Logic

1. **Recurrence trigger** — runs on a timed schedule (default: every 1 minute).
2. **Stored procedure calls** — check SQL tables/views for:
   - Scheduled notifications  
   - Team notification lists  
   - Procedure error logs  
   - Overdue tasks
3. **Conditional branches:**
   - If emails are required → send via Office 365.
   - If Teams alerts are required → post to channel/chat.
   - If message size exceeds limits → create file in SharePoint and send link.
4. **Audit trail** — log all events and errors back into SQL.

---
