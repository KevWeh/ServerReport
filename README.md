# Server Parameter Monitoring Script 

This project is an enhanced version of the [SystemReport](https://github.com/KevWeh/SystemReport) script. The basic functionality has been greatly improved, necessitating the creation of a completely new repository. Critical systems on the server are monitored, and if an error occurs, the system administrator is informed via an email report. The script is designed to help system administrators maintain server health and quickly identify potential problems.

## Contents

- [Features](#features)
- [ServerReport vs. SystemReport](#serverreport-vs-systemreport)
- [Installation](#installation)
- [Usage](#usage)
- [Technologies](#technologies)
- [File Output](#file-output)
- [License](#license)

## Features

- **Disk Space Monitoring**: Logs the current disk space usage.
    - Monitoring levels: 0% - 59% = OK | 60% - 80% = CHECK! | 81% - 100% = CRITICAL!
- **Web Services Monitoring**: Checks and logs the status of specified web services.
    - Status: OK | !DOWN!
- **Log Files Amount Monitoring**: Summarises the number of log files in a specified directory.
    - Currently set values: ≤ 10 Files = OK | > 10 Files = ERROR
- **Log Files Size Monitoring**: Summarises the size of log files in a specified directory.
    - Currently set values: ≤ 10MB = OK | > 10MB = ERROR
- **Email Notification**: Sends the report via email in a well-formatted HTML message when any error occurs.

## ServerReport vs. SystemReport
|                    | ServerReport                      | SystemReport                          |
|--------------------|-----------------------------------|---------------------------------------|
| Check interval:    | every 15 min                      | twice a day                           |
| Cron job settings: | `15 * * * *`                      | `0 6 * * *` / `0 13 * * *`            |
| Email report:      | only when an error occurs         | twice a day                           |
| Report details:    | only faulty entries are displayed | all details are displayed permanently |
| Check Logfiles:    | Amount and size separately        | Amount and size combined              |

## Installation

1. **Save the script file:**

   Save the script in a directory of your choice. Example:
   ```bash
   /usr/local/bin/serverreport.sh
   ```

2. **Make the script executable:**
   ```bash
   chmod +x /usr/local/bin/serverreport.sh
   ```


3. **Configure email settings:**

   Ensure `msmtp` is installed and configure it as follows:
   ```bash
   sudo apt-get install msmtp
   sudo nano /etc/msmtprc
   ```
   Example configuration:
   ```bash
   defaults
   tls on
   tls_trust_file /etc/ssl/certs/ca-certificates.crt

   account default
   host smtp.example.com
   from your-email@example.com
   auth on
   user your-username
   password your-password
   logfile ~/.msmtp.log
   ```


4. **Configure crontab:**

    Open the `crontab` settings in sudo mode:
    ```shell
    sudo crontab -e
    ```

    Underneath the comment section, add the following entry:
    ```shell
    15 * * * * /usr/local/bin/serverreport.sh >/dev/null 2>&1
    ```

## Usage

- Run the script with the following command:

   ```bash
   /usr/local/bin/serverreport.sh
   ```

## Technologies
- **Bash:** The scripting language used to write the script.
- **msmtp:** A lightweight SMTP client used to send email notifications.
- **crontab:** A time-based job scheduler.

## File Output

Possible error messages (sent via email if any errors appear):
```
##########################################################
#   ________   ___  __   _____   ______       _______ __ #
#  / ___/ _ | / _ \/ /  /  _/ | / / __/____  / ___/ // / #
# / /__/ __ |/ ___/ /___/ / | |/ / _/ /___/ / /__/ _  /  #
# \___/_/ |_/_/  /____/___/ |___/___/       \___/_//_/   #
#                                                        #
##########################################################

                     28.06.24 - 01:58

       Speicherplatz:.....................37% | OK
       Webservices:.............................OK
       Anzahl Logfiles:.........................OK
       Groesse Logfiles:........................OK
```

Possible error messages (sent via email if anyone of the errors appear):
```
 
##########################################################
#   ________   ___  __   _____   ______       _______ __ #
#  / ___/ _ | / _ \/ /  /  _/ | / / __/____  / ___/ // / #
# / /__/ __ |/ ___/ /___/ / | |/ / _/ /___/ / /__/ _  /  #
# \___/_/ |_/_/  /____/___/ |___/___/       \___/_//_/   #
#                                                        #
##########################################################

                     28.06.24 - 01:59

       Speicherplatz:..............37% | CRITICAL!
       Webservices:..........................ERROR
       | Service 1       ...................!DOWN!
       | Service 2       ...................!DOWN!
       | Service 3       ...................!DOWN!
       | Service 4       ...................!DOWN!
       | Service 5       ...................!DOWN!

       Anzahl Logfiles:......................ERROR
       | Service1*.log         ...........27 Files
       | Service2*.log         ...........26 Files
       | Service3*.log         ...........28 Files

       Groesse Logfiles:.....................ERROR
       | Service1.log.1                ........13M
       | Service1.log.2                ........11M
       | Service2.log.1                ........11M

```

## License

- This script is licensed under the MIT License. For more information, see the [LICENSE](./LICENSE) file.
