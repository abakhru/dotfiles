import java.util.Map;

import org.json.simple.*;

public class Foo
{
  static String json = "{\"one\":\"won\",\"two\":2,\"three\":false}";

  public static void main(String[] args)
  {
    JSONObject jsonObject = JSONObject.toJSONString(json);
    Map map = jsonObject;
    System.out.println(map);
  }
}
