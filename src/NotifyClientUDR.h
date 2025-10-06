/*
 * NotifyClient UDR - Header File
 * 
 * Firebird UDR (User Defined Routine) for sending messages
 * over TCP to the calling client
 */

#ifndef NOTIFY_CLIENT_UDR_H
#define NOTIFY_CLIENT_UDR_H

#define FB_UDR_STATUS_TYPE ::Firebird::ThrowStatusWrapper

#include "ibase.h"
#include "firebird/UdrCppEngine.h"
#include <string>
#include <sstream>
#include <iomanip>
#include <cstring>
#include <cctype>
#include <ctime>
#include <algorithm>
#include <vector>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

namespace
{
    template <typename T>
    class AutoReleaseClear
    {
    public:
        static void clear(T* ptr)
        {
            if (ptr)
                ptr->release();
        }
    };

    template <typename T, typename Clear>
    class AutoImpl
    {
    public:
        AutoImpl<T, Clear>(T* aPtr = NULL)
            : ptr(aPtr)
        {
        }

        ~AutoImpl()
        {
            Clear::clear(ptr);
        }

        AutoImpl<T, Clear>& operator =(T* aPtr)
        {
            Clear::clear(ptr);
            ptr = aPtr;
            return *this;
        }

        operator T*()
        {
            return ptr;
        }

        operator const T*() const
        {
            return ptr;
        }

        bool operator !() const
        {
            return !ptr;
        }

        T* operator ->()
        {
            return ptr;
        }

        T* release()
        {
            T* tmp = ptr;
            ptr = NULL;
            return tmp;
        }

        void reset(T* aPtr = NULL)
        {
            if (aPtr != ptr)
            {
                Clear::clear(ptr);
                ptr = aPtr;
            }
        }

    private:
        AutoImpl<T, Clear>(AutoImpl<T, Clear>&);
        void operator =(AutoImpl<T, Clear>&);

    private:
        T* ptr;
    };

    template <typename T> class AutoRelease : public AutoImpl<T, AutoReleaseClear<T> >
    {
    public:
        AutoRelease(T* ptr = NULL)
            : AutoImpl<T, AutoReleaseClear<T> >(ptr)
        {
        }
    };

    // JSON string escape function
    inline std::string jsonEscape(const std::string& str)
    {
        std::ostringstream o;
        for (size_t i = 0; i < str.length(); ++i)
        {
            switch (str[i])
            {
                case '"': o << "\\\""; break;
                case '\\': o << "\\\\"; break;
                case '\b': o << "\\b"; break;
                case '\f': o << "\\f"; break;
                case '\n': o << "\\n"; break;
                case '\r': o << "\\r"; break;
                case '\t': o << "\\t"; break;
                default:
                    if (static_cast<unsigned char>(str[i]) <= 0x1f)
                    {
                        o << "\\u" 
                          << std::hex << std::setw(4) 
                          << std::setfill('0') 
                          << static_cast<int>(static_cast<unsigned char>(str[i]));
                    }
                    else
                    {
                        o << str[i];
                    }
            }
        }
        return o.str();
    }
}

#endif // NOTIFY_CLIENT_UDR_H

