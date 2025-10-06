/*
 * NotifyClient UDR - Implementation
 * 
 * Firebird UDR for sending messages over TCP to the client
 */

#include "NotifyClientUDR.h"

using namespace Firebird;

/***
create procedure notify_client (
    header varchar(200),
    level varchar(50),
    subject varchar(200),
    referenz integer,
    message varchar(1000),
    ipv4_address varchar(15),
    port integer
)
returns (
    result integer,
    timestamp_value timestamp,
    used_ip_address varchar(15),
    summary_message varchar(1500)
)
    external name 'notify_client_udr!notify_client'
    engine udr;
***/

FB_UDR_BEGIN_PROCEDURE(notify_client)
    // Input message structure
    FB_UDR_MESSAGE(InMessage,
        (FB_VARCHAR(200), header)
        (FB_VARCHAR(50), level)
        (FB_VARCHAR(200), subject)
        (FB_INTEGER, referenz)
        (FB_VARCHAR(1000), message)
        (FB_VARCHAR(15), ipv4_address)
        (FB_INTEGER, port)
    );

    // Output message structure
    FB_UDR_MESSAGE(OutMessage,
        (FB_INTEGER, result)
        (FB_TIMESTAMP, timestamp_value)
        (FB_VARCHAR(15), used_ip_address)
        (FB_VARCHAR(1500), summary_message)
    );

    FB_UDR_CONSTRUCTOR
    {
        // No special initialization needed
    }

    FB_UDR_EXECUTE_PROCEDURE
    {
        // Reset fetch counter
        fetched = false;
        
        try {
        // Read input parameters
        std::string header((char*)in->header.str, in->header.length);
        std::string level((char*)in->level.str, in->level.length);
        std::string subject((char*)in->subject.str, in->subject.length);
        int referenz = in->referenz;
        std::string message((char*)in->message.str, in->message.length);
        std::string providedIP((char*)in->ipv4_address.str, in->ipv4_address.length);
        int port = in->port;
        
        // Port validation: if <= 0 or NULL, use default port
        if (port <= 0) {
            port = 1526;
        }
        
        // Determine IP address
        std::string clientIP = "127.0.0.1"; // Fallback if no valid IP provided
        
        // Function for IPv4 validation
        auto isValidIPv4 = [](const std::string& ip) -> bool {
            if (ip.empty() || ip.length() > 15) return false;
            
            // Simple IPv4 validation: 4 numbers between 0-255, separated by dots
            size_t dotCount = 0;
            for (char c : ip) {
                if (c == '.') dotCount++;
                else if (!std::isdigit(static_cast<unsigned char>(c))) return false;
            }
            if (dotCount != 3) return false;
            
            // Check if numbers are between 0-255
            try {
                std::istringstream ss(ip);
                std::string segment;
                int segmentCount = 0;
                while (std::getline(ss, segment, '.')) {
                    if (segment.empty() || segment.length() > 3) return false;
                    int num = std::stoi(segment);
                    if (num < 0 || num > 255) return false;
                    segmentCount++;
                }
                return segmentCount == 4;
            } catch (...) {
                return false;
            }
        };
        
        // Use provided IP if it is valid
        if (!providedIP.empty() && isValidIPv4(providedIP)) {
            clientIP = providedIP;
        } else {
            // No SELECTs allowed within UDR → keep fallback
            clientIP = "127.0.0.1";
        }
        
        // Create JSON message
        std::ostringstream json;
        json << "{"
             << "\"HEADER\":\"" << jsonEscape(header) << "\"," 
             << "\"LEVEL\":\"" << jsonEscape(level) << "\"," 
             << "\"SUBJECT\":\"" << jsonEscape(subject) << "\"," 
             << "\"REFERENZ\":" << referenz << "," 
             << "\"MESSAGE\":\"" << jsonEscape(message) << "\"" 
             << "}";
        
        std::string jsonStr = json.str();
        
        // Establish TCP connection and send message
        int sendResult = 0; // 0 = error, 1 = success
        int sock = socket(AF_INET, SOCK_STREAM, 0);
        if (sock >= 0)
        {
            // Set timeout (2 seconds)
            struct timeval timeout;
            timeout.tv_sec = 2;
            timeout.tv_usec = 0;
            setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));
            setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
            
            struct sockaddr_in serverAddr;
            memset(&serverAddr, 0, sizeof(serverAddr));
            serverAddr.sin_family = AF_INET;
            serverAddr.sin_port = htons(port);
            
            // Convert client IP to sockaddr
            if (inet_pton(AF_INET, clientIP.c_str(), &serverAddr.sin_addr) > 0)
            {
                // Establish connection
                if (connect(sock, (struct sockaddr*)&serverAddr, sizeof(serverAddr)) == 0)
                {
                    // Send message
                    if (send(sock, jsonStr.c_str(), jsonStr.length(), 0) > 0)
                    {
                        sendResult = 1; // Success
                    }
                }
            }
            
            // Close socket
            close(sock);
        }
        
        // Get current time
        ISC_TIMESTAMP now;
        time_t rawtime;
        struct tm timeinfo;
        time(&rawtime);
        localtime_r(&rawtime, &timeinfo);
        
        // Create Firebird timestamp
        now.timestamp_date = 0;
        now.timestamp_time = 0;
        isc_encode_timestamp(&timeinfo, &now);
        
        // Create summary
        std::ostringstream summary;
        summary << header << " | " << level << " | " << subject << " | " << referenz << " | " << message;
        std::string summaryStr = summary.str();
        
        // Set output parameters
        out->resultNull = FB_FALSE;
        out->result = sendResult;
        
        out->timestamp_valueNull = FB_FALSE;
        out->timestamp_value = now;
        
        out->used_ip_addressNull = FB_FALSE;
        size_t ipLen = clientIP.length();
        if (ipLen > 15) ipLen = 15; // Maximum 15 characters for IPv4
        memcpy(out->used_ip_address.str, clientIP.c_str(), ipLen);
        out->used_ip_address.length = ipLen;
        
        out->summary_messageNull = FB_FALSE;
        size_t summaryLen = summaryStr.length();
        if (summaryLen > 1500) summaryLen = 1500; // Maximum 1500 characters
        memcpy(out->summary_message.str, summaryStr.c_str(), summaryLen);
        out->summary_message.length = summaryLen;
        
        } catch (const std::exception& e) {
            // On error: Set safe output values
            out->resultNull = FB_FALSE;
            out->result = -1; // -1 = error in UDR
            
            out->timestamp_valueNull = FB_TRUE;
            out->used_ip_addressNull = FB_TRUE;
            out->summary_messageNull = FB_TRUE;
        } catch (...) {
            // On unknown error: Set safe output values
            out->resultNull = FB_FALSE;
            out->result = -2; // -2 = unknown error
            
            out->timestamp_valueNull = FB_TRUE;
            out->used_ip_addressNull = FB_TRUE;
            out->summary_messageNull = FB_TRUE;
        }
    }

    // Fetch procedure for the ResultSet
    FB_UDR_FETCH_PROCEDURE
    {
        // On first call: return row (true)
        // On further calls: no more rows (false)
        if (!fetched) {
            fetched = true;
            return true;
        }
        return false;
    }

    // Variable for fetch status
    bool fetched;

FB_UDR_END_PROCEDURE


// Factory registration
FB_UDR_IMPLEMENT_ENTRY_POINT
