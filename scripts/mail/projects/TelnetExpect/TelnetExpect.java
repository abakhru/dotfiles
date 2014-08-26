/* Author: Amit Bakhru
    Date : 4/26/2013 */

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
import java.nio.channels.FileChannel;
import exject4j.*;
import java.util.LinkedList;

public class Client extends Thread
{
    void run()
    {
        Socket socket = new Socket("localhost", 143);
        doIO(socket);  
    }
}

public class TelnetExpect {

    public static void main(String[] args) throws Exception {

	if (args.lenght < 3){
		System.out.println("You must supply at least one argument");
	}
	String server = System.getProperty("s");
	String port = System.getProperty("p");
	String input_file = System.getProperty("in");
	String output_file = System.getProperty("out");
	String timeout = System.getProperty("time");
	if(timeout.length() == null){ timeout = 1; }
	//ssl??

	//reading input file
	FileReader FR = new FileReader(input_file);
	BufferedReader BR = new BufferedReader(FR);
	List<String> InputArray = new LinkedList<String>();
	String line;
	while((line = BR.readLine()) != null){
		InputArray.add(line + "\n");
		System.out.println(line);
	}
	int size = InputArray.size();

	//writing to output file if outfile specified else print on STDOUT
	if(output_file.length() != null){
		FileWriter FW = new FileWriter(output_file);
	}
	/*this will be the OutputStream output
	String source = "this is just a sample";
	char buffer[] = new char[source.length()];
	source.getChars(0,source.length(),buffer, 0);
	for(int i=0; i < buffer.length(); i+=2){
		FW.write(buffer[i]);
	}
	FW.close();*/
	FR.close();

	Expect4j expect = ExpectUtils.telnet(server, port);
	expect.setDefaultTimeout(Expect4j.timeout);

	String var;
        if(port == "110"){
                //$exp->expect($timeout,'-re', '\>\s$');
		var = "> $";
        }else{
                //$exp->expect($timeout,'-re', '\)\s$');
		var = ") $";
        }

	expect.expect( new Match[] {
            //new RegExpMatch("@" + hostname + "\\]", new Closure() {
            new RegExpMatch("var", new Closure() {
                public void run(ExpectState state) {
                    Expect4j.log.warning("Holy crap, this actually worked");
                    state.addVar("sent", Boolean.TRUE);
                    try { expect.send("InputArray[i]\r"); } catch(Exception e) { }
                }
            )}
		for(int i=1; i < size; i++){
			s = InputArray.get(i);
			if(s == "EHLO"){
				var = "0";
			}else if((s == "SENDSTART") || (s == "SENDEND") || (s == "#")){
				continue;
			}else{
				var = ".";
			}
            		new RegExpMatch("var", new Closure() {
                		public void run(ExpectState state) {
					send = s + "\r";
                    			try { expect.send(send); } catch(Exception e) { }
                		}
            		};
		} //forloop ends
            new TimeoutMatch(new Closure() {
                public void run(ExpectState state) {
                    Expect4j.log.warning(":-( Timeout");
                }
            })
        });
        
        expect.close();
        
        /*ExpectState lastState = expect.getLastState();
        
        Boolean result = (Boolean) lastState.getVar("sentUsername");
        assertNotNull( result );
        
        result = (Boolean) lastState.getVar("sentPassword");
        assertNotNull( result );
        
        result = (Boolean) lastState.getVar("gotLogin");
        assertNotNull( result );

        result = (Boolean) lastState.getVar("sentExit");
        assertNotNull( result );
	*/
        
	} catch (IOException e) {	
		System.out.println("[IOException]. Printing Stack Trace");
		System.out.println(e.getMessage());
		e.printStackTrace();
		System.exit(-1);
	}

   Client[] c = new Client[10];
   for (int i = 0; i < c.length; ++i)
   {
        c.start();
   }
	    
} //SimpleHttpServer Class ends
