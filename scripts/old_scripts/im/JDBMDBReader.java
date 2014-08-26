//package com.sun.im.tools.redirect;

import jdbm.*;
import jdbm.recman.*;
import jdbm.hash.*;
import jdbm.helper.*;
import java.io.*;
public class JDBMDBReader {
    private final static String NAME_LOOKUP_TABLE = "redirect_table";
    private final static String INPUT_FILE_DEFAULT = "redirect";
    private final static String OUTPUT_FILE_DEFAULT = "redirect.txt";
    private String _inputFileName = INPUT_FILE_DEFAULT;
    private String _outputFileName = OUTPUT_FILE_DEFAULT;
    public static void main(String args[]) throws Exception {
        JDBMDBReader reader = new JDBMDBReader();
        if(reader.parseArgs(args)) {
            reader.writeOut();
        }
    }

    public boolean parseArgs(String args[]) {
        int length = args.length;
        if(length > 0) {
            if((length % 2) == 0) {
                for(int i = 0; i < length; i++) {
                    if("-i".equalsIgnoreCase(args[i])) {
                        _inputFileName = args[++i];
                    } else if("-o".equalsIgnoreCase(args[i])) {
                        _outputFileName = args[++i];
                    } else {
                        printUsage();
                        return false;
                    }
                }
            } else {
                printUsage();
                return false;
            }
        }
        return true;
    }

    public void writeOut() throws Exception {
        RecordManager recman = new RecordManager(_inputFileName);
        recman.disableTransactions();
        ObjectCache cache = new ObjectCache(recman, new MRU(100));
        HTree userLookup = HTree.load(
            recman, cache, recman.getNamedObject(NAME_LOOKUP_TABLE));
        JDBMEnumeration e = userLookup.keys();
        BufferedWriter bw = null;
        try {
            FileWriter fw = new FileWriter(_outputFileName);
            bw = new BufferedWriter(fw);
            while(e.hasMoreElements()) {
                Object uid = e.nextElement();
                Object partition = userLookup.get(uid);
                bw.write(partition + " "  + uid + "\n");
            }
        } finally {
            if(bw != null) {
                bw.flush();
                bw.close();
            }
        }
    }
    public static void printUsage() {
        System.out.println(
            "Usage: " +
               "java com.sun.im.tools.redirect.JDBMDBReader " + 
               "[-i input_db_file_without_ext -o output_file]");
    }
}

