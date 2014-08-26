import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
 
import org.json.simple.*;
 
public class JsonMain {
    public static void main(String[] args) {
         
        Map<String, Long> map = new HashMap<String, Long>();
        map.put("A", 10L);
        map.put("B", 20L);
        map.put("C", 30L);
         
	String jsonString = JSONValue.toJSONString(map);
  	System.out.println(jsonString);
         
        List<String> list = new ArrayList<String>();
        list.add("Sunday");
        list.add("Monday");
        list.add("Tuesday");
         
	String jsonString1 = JSONValue.toJSONString(list);
  	System.out.println(jsonString1);
    }
}
