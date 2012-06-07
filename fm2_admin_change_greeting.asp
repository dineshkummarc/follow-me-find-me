<%@ LANGUAGE = VBScript %>

<!-- #include file="subs.asp" -->

<%
  ' ---------------------------------------------------
  ' copyright 2000 by voxeo corporation. (see LGPL.txt)
  '
  ' v1.0 Coded in ASP
  ' v1.0 Coded by Ryan Campbell and Stephen J. Lewis
  ' ---------------------------------------------------

Call WriteHeaders  
  
Dim conntemp, SQLRec

call OpenDatabase

Set SQLRec = Server.CreateObject ("ADODB.Recordset")

'----------------------------------------------------
' The "Action" variable passed along the QueryString 
' controls which of the two options are used in this
' file.  If Action equals "Update," then the greeting
' file name is being changed inside the database,
' otherwise the caller hears the sequence of prompts
' to record a new greeting file.
'----------------------------------------------------

Action = Request.QueryString("Action")
	Select Case Action
		Case "Update"
		  On Error Resume Next
		  sqlUpdate = "UPDATE Users SET GreetingFile = '" & Request.QueryString("NFilename") & "' WHERE phone_number = '" & Request.QueryString("session.calledid") & "'"
		  Set SQLRec = conntemp.Execute (sqlUpdate)
			  
          If Err.Number <> 0 Then
 			Response.Write "<playaudio format=""audio/wav"" value=""$audiorootdir;/changeGreetingError.wav""/>"
		  else
 			Response.Write "<playaudio format=""audio/wav"" value=""$audiorootdir;/changeGreetingSuccess.wav""/>"
		  end if			
			
		  '-----------------------
		  ' now close and clean up
		  '-----------------------
		  
		  SQLRec.Close
		  Set SQLRec = NOTHING    
		  Response.Write "<goto value=""$rootdir;/fm2_admin_menu.XML"" submit=""*"" method=""get"" />"
		  
		Case Else			
	  	  On Error Resume Next	  
		  
		  '--------------------------------
		  ' now find the user's information
		  '--------------------------------
		  
		  SQLStr = "Select * from users Where phone_number = '" & Request.QueryString("session.calledid") & "'"
		  set SQLRec = conntemp.Execute (SQLStr)
		
		  if (Err.Number <> 0) or (SQLRec.eof) then
 			response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/cannotFindAccount.wav""/>"
		    response.write "<hangup/>"
		  else
		    '-----------------------------------------------------
		    ' Here we are extracting the filename prior to the "."
			' I am sure there is a much easier way of doing this
			' in ASP, but I do not know what it is.
			'-----------------------------------------------------
		  
			OriginalStr = SQLRec("GreetingFile")
		    StrLength   = len(OriginalStr)
			TempStr     = ""
			TempBoolean = "NO"
			
			For Loopy = 0 to StrLength
              TempChar = Mid(OriginalStr, Loopy, 1)

			  if TempChar = "." then
			    TempBoolean = "YES"
			  end if
			  
			  if TempBoolean <> "YES" then
			    TempStr = TempStr + TempChar
			  end if
			Next
			
  		    Offset = request("offset")
		  
		    if (Offset = "") Then
		      Offset = 1
		    Else
		      Offset = Offset + 1
		    End If
			
			TempInt     = (Int(TempStr)) + Offset
		    OldFileName = OriginalStr
		    NewFileName = TempInt & ".wav"
			
			'---------------------------------------------
			' If the new file name is empty, make it 1.wav
			'---------------------------------------------
			
			if NewFileName = ".wav" then
			  NewFileName = "1.wav"
			end if
		  end if

		  '-----------------------
		  ' now close the database
		  '-----------------------
		  
		  Call CloseDatabase
		  
		  Offset = request("offset")
		  
		  if (Offset = "") Then
		    Offset = 1
		  Else
		    Offset = Offset + 1
		  End If
			
	  	  Response.Write "<block label=""main"" cleardigits=""true"">"
		  response.write "<assign var=""OFilename"" value=""" & OldFileName & """/>"	  
		  response.write "<assign var=""NFilename"" value=""" & NewFileName & """/>"
		  response.write "<assign var=""offset""    value=""" & Offset      & """/>"
		  
		  '-----------------------------------------------------
		  ' We need to check and see if our FTP server requires
		  ' a username and password to be sent in.  Those values
		  ' are set in the subs.asp include file.
		  '-----------------------------------------------------
		  
		  if ( (GetFTPUsername <> "") and (GetFTPPassword <> "" ) ) then
		    FTPText = GetFTPUsername & ":" & GetFTPPassword & "@"
		  else 
		    FTPText = ""
		  end if
		  
		  if request("Rerecording") <> "YES" then
%>		
	    <block label="recordNewPrompt" repeat="3">
	      <playaudio format="audio/wav" value="$audiorootdir;/changeGreeting.wav" termdigits="12*"
	    	         cleardigits="TRUE"/>
	
	      <!-- ===================================== -->
	      <!-- Play current greeting                 -->
		  <!--                                       -->
		  <!-- Pressing 1 returns is to re-record    -->
		  <!-- Pressing 2 will record a new greeting -->
		  <!-- Pressing * returns to the admin menu  -->
		  <!-- ===================================== -->
		  
	      <ontermdigit value="1">
	        <playaudio format="audio/wav" value="http://$ftprootdir;/$session.calledid;/$OFilename;"/>
	        <goto value="#main" submit="*" method="get" />
			
      		<goto value="$rootdir;/fm2_admin_change_greeting.asp" submit="*" method="get" />	  			
	      </ontermdigit>
		  
		  <!-- ================ -->
	      <!-- Get new greeting -->
		  <!-- ================ -->
		  
	      <ontermdigit value="2">
<%      end if %>
		
	        <block label="recordPrompt">
	          <playaudio format="audio/wav" value="$audiorootdir;/recordAfterTone.wav" cleardigits="TRUE" 
			             termdigits="#*"/>
<%						 			  
	          response.write "<recordAudio format=""audio/wav"" " & _
			  							  "value=""ftp://" & FTPText & "$ftprootdir;/$session.calledid;/$NFilename;"" " & _
										  "termdigits=""#"" " & _
	                       				  "clearDigits=""TRUE"" " & _
										  "maxtime=""60s"" " & _
										  "maxsilence=""10s"" " & _
										  "beep=""true""/>"
%>						   
	          <onerror>
 			    <playaudio format="audio/wav" value="$audiorootdir;/changeGreetingError.wav"/>"			  
			  </onerror>
			  
			  <ontermdigit value="#">
			    <!-- ========================================================= -->
	            <!-- verify new greeting before replacing the current greeting -->
				<!-- ========================================================= -->
				 
				<block label="verifyRecord" repeat="3" clearDigits="TRUE">
	              <playaudio format="audio/wav" value="$audiorootdir;/youRecorded.wav" termdigits="12*"
	          	           cleardigits="FALSE"/>
	              <playaudio format="audio/wav" value="http://$ftprootdir;/$session.calledid;/$NFilename;" termdigits="12*"
	          	           cleardigits="FALSE"/>
	              <playaudio format="audio/wav" value="$audiorootdir;/KeepOrRerecord.wav" termdigits="12*"
	          	           cleardigits="FALSE" />
						   
				  <!-- ================================================================== -->
				  <!-- If 1 is pressed then replace the current greeting with the new one -->
				  <!-- ================================================================== -->
				  
	              <ontermdigit value="1"> 
					<goto value="$rootdir;/fm2_admin_change_greeting.asp?Action=Update" submit="*" method="get" />		  
				  </ontermdigit>
				  
				  <!-- =========================================== -->
				  <!-- If 2 is pressed then re-record the greeting -->
				  <!-- =========================================== -->
				  
	              <ontermdigit value="2"> 
				    <goto value="$rootdir;/fm2_admin_change_greeting.asp?Rerecording=YES" submit="*" method="get" />
			      </ontermdigit>
				  
	            </block> <!-- verify record -->
	          </ontermdigit>
	        </block> <!-- recordPrompt-->
<%
     if request("Rerecording") <> "YES" then
%>	 			
	      </ontermdigit>
		  
	      <ontermdigit value="*">
		    <goto value="$rootdir;/fm2_admin_menu.xml" submit="*" method="get" />
	      </ontermdigit>
		  
	      <onmaxtime/>
	      <onmaxsilence/>
	   </block> <!-- recordNewPrompt -->
	   
<%   else  %>
	   <ontermdigit value="*">
		 <goto value="$rootdir;/fm2_admin_menu.xml" submit="*" method="get" />
	    </ontermdigit>
<%   end if  %>

	  </block> <!-- main -->
	  
	  <!-- ======================== -->
	  <!-- Return to the admin menu -->
	  <!-- ======================== -->
	  
      <goto value="$rootdir;/fm2_admin_menu.xml" submit="*" method="get" />	  
<%End Select

Call WriteFooters

%>