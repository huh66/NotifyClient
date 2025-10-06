using System.Net.Sockets;
using System.Text;
using System.Text.Json;

class TestClient
{
    static void Main()
    {
        var msg = new
        {
            HEADER = "TestHeader",
            LEVEL = "INFO",
            SUBJECT = "TestSubject",
            REFERENZ = 123,
            MESSAGE = "Hello from client!"
        };
        var json = JsonSerializer.Serialize(msg);
        using (var client = new TcpClient("127.0.0.1", 1526))
        using (var stream = client.GetStream())
        {
            var data = Encoding.UTF8.GetBytes(json);
            stream.Write(data, 0, data.Length);
        }
        Console.WriteLine("Message sent.");
    }
}