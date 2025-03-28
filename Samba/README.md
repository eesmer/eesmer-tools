# eesmer-tools/Samba
Scripts and Configs for Samba Active Directory

---

### Samba Active Directory Installer
- It installs the Samba package and its requirements.
- It installs and configures bind9 for DNS.
- It installs and configures the chrony service for the NTP service. <br>
<br>
Then, it performs the Domain Name Provisioning process according to the information it receives and configures the smb.conf file.
The machine on which it is run takes the PDC role and starts working as a DC for the established domain. <br>
<br>

As the `root`: <ins>perform operations as root user.!!</ins> <br>
It should be run in a Debian 11 or Debian 12 environment.

#### 🛠️ Requirements
- Debian 11,12

#### 📦 Install
```
bash  samba-activedirectory-installer.sh
```

---

### Samba Active Additional Domain Controller Installer
It connects to the Domain Controller server in the Samba Active Directory environment and adds an ADC server to the Domain environment.

#### 🛠️ Requirements
- Debian 11,12
- Samba Active Directory Environment

#### 📦 Install
```
bash samba-activedirectory-additional-dc-joiner.sh
```

---

### Samba Active Directory Hardening
Hardening settings in Active Directory environment where Samba is required

#### 🛠️ Requirements
- Debian 11,12
- Samba Active Directory Environment

#### 📦 Install
```
bash samba-activedirectory-hardening.sh
```

---

### Samba Active Directory Domain Reporting Tool
It runs on the Domain Controller, checks the Active Directory configuration and gives an analysis output.

#### 🛠️ Requirements
- Debian 11,12
- Samba Active Directory Domain Controller

#### 📦 Install
```
bash samba-activedirectory-reporting-tool.sh
```

---

### Samba Active Directory User Accounts Reporting Tool
Provides a report that examines user accounts via Domain Controller.

#### 🛠️ Requirements
- Debian 11,12
- Samba Active Directory Domain Controller

#### 📦 Install
```
bash samba-activedirectory-users-report.sh
```

---

### smb.conf
smb.conf containing recommended configurations

#### 🛠️ Requirements
- Debian 11,12
- Samba Active Directory Environment


```
/etc/samba/smb.conf
```

---
