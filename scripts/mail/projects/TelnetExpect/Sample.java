import java.io.*;

public class Sample
{
	public static void main(String[] args) throws Exception {
		try{
			if (args.length() < 3){
                		System.out.println("You must supply at least one argument");
				usage();
			}
        		String server = System.getProperty("s");
        		String port = System.getProperty("p");
        		String input_file = System.getProperty("in");
        		String output_file = System.getProperty("out");
        		String timeout = System.getProperty("time");
        		if(timeout.isEmpty()){ timeout = 1; }
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

			System.out.println("Hello world");
		}
		catch (Exception e) {
			System.out.println("Error" + e.getMessage());
		}
	}
	public static void usage(){
		System.out.print ("Usage: Sample -s <hostname> -p <port> -i <input_file> -o <output_file> -t <seconds>");
		System.exit();
	}
}
