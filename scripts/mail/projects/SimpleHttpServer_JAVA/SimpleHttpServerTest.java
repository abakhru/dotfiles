import junit.framework.*;
import java.io.IOException;
import java.io.InputStream;
 
public class SimpleHttpServerTest extends TestCase {
  private LocalTestServer server = null;
 
  @Mock
  HttpRequestHandler handler;
 
  @Before
  public void setUp() {
    server = new LocalTestServer(null, null);
    server.register("/someUrl", handler);
    server.register("/cpu_usage", handler);
    server.register("/response", handler);
    server.start();
 
    // report how to access the server
    String serverUrl = "http://" + server.getServiceHostName() + ":" + server.getServicePort();
    System.out.println("LocalTestServer available at " + serverUrl);
  }
 
  // do lots of testing!
 
  @After
  public void tearDown() {
    server.stop();
  }
}
