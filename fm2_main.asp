<%@ LANGUAGE = VBScript %>

<!-- #include file="subs.asp" -->

<%
  ' ---------------------------------------------------
  ' copyright 2000 by voxeo corporation. (see LGPL.txt)
  '
  ' v1.0 Coded in ASP
  ' v1.0 Coded by Ryan Campbell and Stephen J. Lewis
  ' ---------------------------------------------------
%>  

<?xml version="1.0" encoding="UTF-8"?>

<callxml>

  <block label="main_menu">
    <assign var="rootdir"      value="http://appserverdev.voxeo.com/fm2"/>
	<assign var="audiorootdir" value="http://appserverdev.voxeo.com/fm2/audio"/>
	<assign var="ftprootdir"   value="appserverdev.voxeo.com/applications/fm2"/>
	
	<!-- We need to check the users record to find her greetingfile -->
	
	<%
	Dim SQLRec, conntemp
	
    Call OpenDatabase	
	Set SQLRec = Server.CreateObject ("ADODB.Recordset")
	
	On Error Resume Next	  
	
	CalledID = request("session.calledid")
	
	'------------------------------------------------------
	' Sometimes the AGS passes this variable twice in the 
	' query string, so we have to chop off everything after
	' the comma (which naturally occurs when two variables
	' of the same name are on the query string
	'------------------------------------------------------

	Comma = instr(CalledID, ",")
	while Comma > 0 
	  CalledID = right(CalledID, Comma - 1)
      Comma = instr(CalledID, ",")
	wend
	
	'----------------------------------------
	' Get the greeting file from the database
	'----------------------------------------
	
	SQLStr = "Select * from users Where phone_number = '" & CalledID & "'"
	set SQLRec = conntemp.Execute (SQLStr)
	greetingfile = SQLRec("GreetingFile")
	
	response.write "<assign var=""TheGreetingFile"" value=""" & greetingfile & """/>"

	Call CloseDatabase
	%>

    <!-- play the main menu including the users name, repeat up to 3 times -->

    <block label="loop" repeat="3" cleardigits="false" maxtime="30s">

      <playaudio format="audio/wav"
                 value="$audiorootdir;/CallAnswer.wav"
                 termdigits="12*"
                 cleardigits="false" />
				 				 
      <playaudio format = "audio/wav"
                 value="http://$ftprootdir;/$session.calledid;/$TheGreetingFile;"
		 		 termdigits="12*"
                 cleardigits="false" />
				 
      <playaudio format="audio/wav"
                 value="$audiorootdir;/MainMenu.wav"
		 		 termdigits="12*"
                 cleardigits="false" />

      <ontermdigit value="1"> 
		<goto value="$rootdir;/fm2_Call_and_VM.asp?Action=Mode" submit="*" method="get"/>
	  </ontermdigit>
      <ontermdigit value="2"> 
		<goto value="$rootdir;/fm2_Call_and_VM.asp?Action=SendToVM" submit="*" method="get"/>   	
	  </ontermdigit>
      <ontermdigit value="*"> 
	    <goto value="$rootdir;/fm2_admin.asp" submit="*" method="get" />    
	  </ontermdigit>
    </block>

    <!-- if we get out of the above menu for any reason, hangup -->

    <simline value=")))out of the block"/>

    <hangup/>

  </block>

</callxml>