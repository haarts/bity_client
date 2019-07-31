import "package:http/browser_client.dart";

// By calling this class 'Client' it becomes interchangeable
// with the Client class from package:http/http.dart.
class Client extends BrowserClient {
  Client() {
    withCredentials = true;
  }
}
