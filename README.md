# NotifyClient

Firebird 3.0 User Defined Routine (UDR) for sending messages over TCP to the calling SQL client or any other IP client.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Firebird](https://img.shields.io/badge/Firebird-3.0+-blue.svg)](https://firebirdsql.org/)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)](https://www.linux.org/)

#### Check NotifyPanel for receiving notifications from this client

A Windows Forms application that receives and displays notification messages from a Firebird SQL Server.

https://github.com/huh66/NotifyPanel

#### Check NotifySend for sending notifications from Windows Command Line to NotifyPanel

A C# Windows command-line program for sending messages over TCP sockets.

https://github.com/huh66/NotifySend

## Overview

This UDR allows sending messages directly to connected clients from Firebird triggers or stored procedures. Messages are transmitted as JSON over TCP (default port 1526).

## How it works

1. An SQL trigger (e.g. on INSERT/UPDATE/DELETE) is triggered
2. The trigger calls the UDR procedure `NOTIFY_CLIENT`
3. The UDR determines the IP address of the calling client
4. A TCP connection to Client-IP:PORT is established (default: 1526)
5. The message is sent as JSON
6. The client receives the message and displays it in a MessageBox

## System Requirements

- Linux Debian 13 (or compatible)
- Firebird 3.0.13 or higher
- g++ compiler with C++11 support
- Firebird Development Headers (`firebird3.0-dev`)
- Boost C++ Libraries (`libboost-dev`)


## Installation

### 1. Install dependencies

```bash
sudo apt-get update
sudo apt-get install firebird3.0-dev libboost-dev g++ make
```

### 2. Compile UDR Library

```bash
make
```

This creates the file `simple_message_udr.so`.

### 3. Install library

```bash
sudo make install
```

The library is copied to `/usr/lib/firebird/3.0/plugins/udr/`.

### 4. Register SQL procedure in database

```bash
isql -user SYSDBA -password <your-password> <database> -i install.sql
```

## Usage

### Direct usage

```sql
-- With automatic IP detection and default port
SELECT 
    RESULT,
    TIMESTAMP_VALUE,
    USED_IP_ADDRESS,
    SUMMARY_MESSAGE
FROM NOTIFY_CLIENT(
    'Message Header',
    'INFO',
    'Subject',
    123,
    'This is the message text',
    '',     -- Empty IP = automatic detection
    NULL    -- NULL Port = default port 1526
);

-- With provided IP address and custom port
SELECT 
    RESULT,
    TIMESTAMP_VALUE,
    USED_IP_ADDRESS,
    SUMMARY_MESSAGE
FROM NOTIFY_CLIENT(
    'Message Header',
    'WARN',
    'Subject',
    123,
    'This is the message text',
    '192.168.1.100',  -- Specific IP address
    8080              -- Custom port
);
```

### Usage in triggers

Example for an INSERT trigger:

```sql
SET TERM ^ ;

CREATE TRIGGER MY_TABLE_INSERTED
AFTER INSERT ON MY_TABLE
AS
BEGIN
    EXECUTE PROCEDURE NOTIFY_CLIENT(
        'New Record',
        'INFO',
        'Record added',
        NEW.ID,
        'A new record was inserted into MY_TABLE.',
        '',
        NULL
    );
END ^

SET TERM ; ^
```

Further examples can be found in `example_trigger.sql`.

## Parameters

The `NOTIFY_CLIENT` procedure expects the following parameters:

| Parameter | Typ | Richtung | Beschreibung |
|-----------|-----|----------|--------------|
| HEADER | VARCHAR(200) | IN | Message header/title |
| LEVEL | VARCHAR(50) | IN | Level (e.g. INFO/WARN/ERROR) |
| SUBJECT | VARCHAR(200) | IN | Message subject |
| REFERENZ | INTEGER | IN | Reference number (e.g. record ID) |
| MESSAGE | VARCHAR(1000) | IN | The actual message text |
| IPV4_ADDRESS | VARCHAR(15) | IN | Optional: IPv4 address (e.g. "192.168.1.100") |
| PORT | INTEGER | IN | Optional: Port number (default: 1526) |

The following values are returned:

| RESULT | INTEGER | OUT | Return value: 1 = success, 0 = error |
| TIMESTAMP_VALUE | TIMESTAMP | OUT | Execution timestamp |
| USED_IP_ADDRESS | VARCHAR(15) | OUT | Actually used IP address |
| SUMMARY_MESSAGE | VARCHAR(1500) | OUT | Summarized message |

## JSON Format

The message is sent in the following JSON format:

```json
{
    "HEADER": "Message Header",
    "LEVEL": "INFO",
    "SUBJECT": "Subject",
    "REFERENZ": 123,
    "MESSAGE": "Message Text"
}
```

## Client Program

The client must listen on the configured port (default: 1526) and process incoming JSON messages.

An example client in C# is located in the `TestClient/` directory.

### Start test client

```bash
cd TestClient
dotnet run
```

## Directory Structure

```
NotifyClient/
├── src/
│   ├── NotifyClientUDR.h          # Header file with helper functions
│   └── NotifyClientUDR.cpp        # UDR implementation
├── TestClient/
│   └── TestClient.cs               # Example client in C#
├── Makefile                        # Build script
├── install.sql                     # SQL installation script
├── uninstall.sql                   # SQL uninstallation script
├── example_trigger.sql             # Example triggers
└── README.md                       # This file
```

## Error Handling

- If the client IP cannot be determined, `127.0.0.1` is used as fallback
- If the TCP connection fails, the exception is silently caught
- The transaction is always completed successfully (Fire-and-Forget principle)

## Limitations

1. **Client IP Detection**: The current implementation tries to determine the client IP via Firebird monitoring tables. If this fails, localhost is used.

2. **No Confirmation**: There is no guarantee that the client receives the message. The connection is unidirectional.

3. **Blocking**: The TCP connect can block briefly. In high-frequency environments this could affect performance.

4. **Firewall**: Make sure the used port (default: 1526) is not blocked by a firewall.

## Uninstallation

### Remove SQL procedure

```bash
isql -user SYSDBA -password <ihr-passwort> <datenbank> -i uninstall.sql
```

### Remove library

```bash
sudo rm /usr/lib/firebird/3.0/plugins/udr/notify_client_udr.so
```

### Clean up compiled files

```bash
make clean
```

## Troubleshooting

### Problem: Library not loaded

**Solution**: Check the permissions:
```bash
sudo chown firebird:firebird /usr/lib/firebird/3.0/plugins/udr/simple_message_udr.so
sudo chmod 644 /usr/lib/firebird/3.0/plugins/udr/simple_message_udr.so
```

### Problem: Procedure not found

**Solution**: Make sure `install.sql` was executed successfully:
```bash
isql -user SYSDBA -password <pwd> <database>
SQL> SHOW PROCEDURE NOTIFY_CLIENT;
```

### Problem: Client not receiving messages

**Solution**: 
1. Check if the client is listening on the configured port (default: 1526)
2. Check firewall settings
3. Test with `telnet <client-ip> 1526`

### Problem: Compilation errors

**Solution**: Check if Firebird headers are installed:
```bash
ls -la /usr/include/firebird
```

If not present:
```bash
sudo apt-get install firebird3.0-dev libboost-dev
```

### Problem: Boost headers not found

**Error message**: `fatal error: boost/preprocessor/seq/for_each_i.hpp: not found`

**Solution**: Install Boost:
```bash
sudo apt-get install libboost-dev
```

## Customization

### Change port

The port can be changed in two ways:

1. **Per call**: Use the PORT parameter:
```sql
FROM NOTIFY_CLIENT('Header', 'LEVEL', 'Subject', 123, 'Message', 'IP', 8080);
```

2. **Change default port**: Change the line in `src/SimpleMessageUDR.cpp`:
```cpp
if (port <= 0) {
    port = 1526;  // Change default port here
}
```

### Add timeout

To add a timeout for the TCP connection, you can set socket options before the `connect()` call:

```cpp
struct timeval timeout;
timeout.tv_sec = 2;
timeout.tv_usec = 0;
setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));
```

## License

This software is provided "as is" without any warranty.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Support

For questions or problems please create an issue in the repository.

## Repository

- **GitHub**: [NotifyClient Repository](https://github.com/yourusername/NotifyClient)
- **Issues**: [Report Issues](https://github.com/yourusername/NotifyClient/issues)
- **Releases**: [Latest Releases](https://github.com/yourusername/NotifyClient/releases)

## Version

Version: 1.0
Date: October 2025
Firebird: 3.0.13

