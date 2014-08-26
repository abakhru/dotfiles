//package com.example;

import java.io.IOException;
import java.io.OutputStream;
import java.io.InputStream;
import java.io.DataInputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.io.StringWriter;
import java.io.File;
import java.io.FileWriter;
import java.net.InetSocketAddress;
import java.util.*;
import java.lang.Object.*;
import org.json.simple.*;
import java.nio.channels.FileChannel;
import java.nio.MappedByteBuffer;
import java.nio.charset.Charset;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.Headers;

public class SimpleHttpServer {

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8845), 0);
        server.createContext("/response", new MyHandler());
        server.createContext("/cpu_usage", new CpuHandler());
        server.setExecutor(null); // creates a default executor
        server.start();
    }

    static class MyHandler implements HttpHandler {
        public void handle(HttpExchange t) throws IOException {
	 try {
            String response = "This is the response";
            t.sendResponseHeaders(200, response.length());
            OutputStream os = t.getResponseBody();
            os.write(response.getBytes());
            os.close();
            } catch (IOException e) {
                        System.out.println("[IOException]. Printing Stack Trace");
                        System.out.println(e.getMessage());
                        e.printStackTrace();
                        System.exit(-1);
            }
        }
    }//MyHandler ends

    static class CpuHandler implements HttpHandler {
	public void handle(HttpExchange t) throws IOException {
		try {
			Runtime rt = Runtime.getRuntime();
			Process p = Runtime.getRuntime().exec("./cpu_usage.sh");
			BufferedReader stdInput = new BufferedReader(new InputStreamReader(p.getInputStream()));
			// read the output from the command
			String line;
			int i = 0;
			List<String> Output_Array = new ArrayList<>();
			while((line = stdInput.readLine()) != null) {  // Read line, check for end-of-file
				Output_Array.add(line + "\n");
				//Output_Array.add(line);
    				//System.out.print(Output_Array.get(i));              // Print the line
				i++;
  			}
			int size = Output_Array.size();
			Headers h = t.getResponseHeaders();
			h.add("Accept", "application/json");
			h.add("Content-Type", "application/json");
			t.sendResponseHeaders(200, 0);

			OutputStream os = t.getResponseBody();
			Map<String, String> map = new HashMap<String, String>();

			String s = "";
			for(i=0; i < size; i++){
				s = Output_Array.get(i);
				os.write(s.getBytes());
				String[] parts = s.split("\t");
				map.put(parts[1], parts[0]);
			}
			JSONObject obj = new JSONObject();
			for (String key : map.keySet()) {
    				//System.out.println("Key: " + key + ", Value: " + map.get(key));
				obj.put(key, map.get(key));
			}
			FileWriter file = new FileWriter("/tmp/test.json");
			file.write(obj.toJSONString());
			file.flush();
			file.close();
  			FileInputStream stream = new FileInputStream(new File("/tmp/test.json"));
    			FileChannel fc = stream.getChannel();
    			MappedByteBuffer bb = fc.map(FileChannel.MapMode.READ_ONLY, 0, fc.size());
    			String finalResult = Charset.defaultCharset().decode(bb).toString();
			os.write(finalResult.getBytes());
			os.close();
		} catch (IOException e) {	
			System.out.println("[IOException]. Printing Stack Trace");
			System.out.println(e.getMessage());
			e.printStackTrace();
			System.exit(-1);
		}
	    
	}//handle ends
    }//CpuHandler ends
} //SimpleHttpServer Class ends
