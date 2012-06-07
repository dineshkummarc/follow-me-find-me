<%@ LANGUAGE = VBScript %>

<!-- #include file="subs.asp" -->


<%
  ' ---------------------------------------------------
  ' copyright 2000 by voxeo corporation. (see LGPL.txt)
  '
  ' v1.0 Coded in ASP
  ' v1.0 Coded by Ryan Campbell and Stephen J. Lewis
  ' ---------------------------------------------------
  
  Dim conntemp
  call OpenDatabase
  
  call WriteHeaders
  
  Action = Request.QueryString("Action")
    Select Case Action
	
	  Case "Mode"
		mySQL="select mode, fm2Enabled from users where phone_number ='" & request("session.calledid") & "'"
		
		set rstemp=conntemp.execute(mySQL)
		  '-----------------------------------------------
		  ' First check to see if the user has FM2 Enabled
		  '-----------------------------------------------
		  
		  if NOT rstemp("fm2Enabled") then
		    response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/FM2Disabled.wav""/>"
		    response.write "<goto value=""$rootdir;/fm2_Call_and_VM.asp?Action=NoAnswer"" submit=""*"" method=""get""/>"
		  
		  '---------------------------------------------------------------------
		  ' Mode 1 equals sequential calling, and mode 2 equals parallel calling
		  '---------------------------------------------------------------------
		     
		  elseif rstemp("mode") = 1 then
		    '-------------------------------------------------------------
			' This is a little like icing on the cake, but we are going to 
			' intelligently configure the block repeat for sequential mode
			' dialing so that it repeats the 30 second hold music the
			' same number of times as there are numbers in the database
			'-------------------------------------------------------------
			
			Fm2SQL = "select * from fm2_numbers where user_ID in (" 
			Fm2SQL = FM2SQL & "select ID from users where phone_number ='" & _
			         request("session.calledid") & "') AND enabled=TRUE"
					 
			set rsFM2Numbers = conntemp.execute(Fm2SQL)
			Repetitions      = 0
				
			Do Until rsFM2Numbers.EOF
			  Repetitions = Repetitions + 1
			  rsFM2Numbers.MoveNext
			Loop
			
			Repetitions = Repetitions * 2
			
			'---------------------------------------------
			' Make sure we do not repeat the loop 0 times.
			'---------------------------------------------
			
			if Repetitions = 0 then 
			  Repetitions = 1
			end if
			
			'-----------------------------------------------------------------------
			' Now do the actual Sequential mode callXML which spawns the new session
			'-----------------------------------------------------------------------		 
		  
		    response.write "<assign var=""parentSession"" value=""$session.ID;""/> " &_
			               "<block>" &_
		                   "  <run value=""$rootdir;/fm2_sequential_outbound.asp"" submit=""*"" method=""get"" var=""ChildSessionID""/> " &_
						   "  <block repeat=""" & Repetitions & """>" & _
			               "    <playaudio value=""$audiorootdir;/holdmusic.wav"" termdigit=""#""/>" &_
						   "    <onexternalevent value=""conferenceMe"">" &_
						   "      <conference targetSessions=""$session.eventsenderID;""/> " &_
						   "      <hangup/>" &_	
						   "    </onexternalevent>" &_
						   "    <onexternalevent value=""noAnswer"">" &_
						   "      <goto value=""$rootdir;/fm2_Call_and_VM.asp?Action=NoAnswer"" submit=""*"" method=""get""/>" &_
						   "    </onexternalevent>" &_
					       "    <onexternalevent value=""sendtovm"">" + _
					       "      <goto value=""$rootdir;/fm2_Call_and_VM.asp?Action=SendToVM"" submit=""*"" method=""get""/> " +_
					       "    </onexternalevent>" + _						   
						   "    <ontermdigit value=""#""/>" & _
						   "      <goto value=""$rootdir;/fm2_Call_and_VM.asp?Action=NoAnswer"" submit=""*"" method=""get""/>" &_
						   "    </ontermdigit>" & _						   
						   "  </block>" & _
						   "</block>" & _
						   "<!-- No one answered -->" & _
			               "<onhangup>" &_
			               "  <sendevent session=""$ChildSessionID;"" value=""kill""/>" &_
			               "</onhangup>" &_
						   "<goto value=""$rootdir;/fm2_Call_and_VM.asp?Action=NoAnswer"" submit=""*"" method=""get""/>"

		  '--------------	
		  ' Parallel mode
		  '--------------
		  
		  elseif rstemp("mode") = 2 then  
			response.write "<assign var=""genesisSession"" value=""$session.ID;""/>"
			
			response.write "<run value=""$rootdir;/fm2_parallel_sessionfilter.asp"" submit=""*"" method=""get"" var=""ChildSessionID""/>"
	
		    response.write "<block label=""parallelFM2"" repeat=""3"">" +_
		                   "  <playaudio value=""$audiorootdir;/holdmusic.wav"" termdigits=""#"" />" +_
		                   "  <onexternalevent value=""conferenceMe"">" + _
		                   "    <conference targetsessions=""$session.eventsenderid;""/>" & _
					       "    <hangup/>" & _
			               "  </onexternalevent>"  + _
		                   "  <onexternalevent value=""sendToVM"">" + _
						   "    <simline value=""going to voicemail""/> " +_
		                   "    <goto value=""$rootdir;/fm2_Call_and_VM.asp?Action=SendToVM"" submit=""*"" method=""get""/> " +_
			               "  </onexternalevent>"  + _
						   "  <onexternalevent value=""NoAnswer"">" + _
						   "    <goto value=""$rootdir;/fm2_Call_and_VM.asp?Action=NoAnswer"" submit=""*"" method=""get""/> " +_
						   "  </onexternalevent>" + _
						   "  <ontermdigit value=""#""/>" & _
			               "    <sendevent session=""$ChildSessionID;"" value=""kill""/>" &_
						   "    <goto value=""$rootdir;/fm2_Call_and_VM.asp?Action=NoAnswer"" submit=""*"" method=""get""/>" &_
						   "  </ontermdigit>" & _						   
		  				   "</block>"
						   
			response.write "<onhangup>"
			response.write "  <sendevent session=""$ChildSessionID;"" value=""kill""/>"
			response.write "</onhangup>"
						   
            response.write "<!-- no one answered -->" + _
						   "<sendEvent session=""$ChildSessionID;"" value=""kill""/>" + _
						   "<goto value=""$rootdir;/fm2_Call_and_VM.asp?Action=NoAnswer"" submit=""*"" method=""get""/> "
		  else
		    response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/noSearchModeSet.wav""/>"
		    response.write "<hangup/>"
		  end if
		
		rstemp.close
		set rstemp=nothing  
		
	  '---- ---------------------------------------------------------------
	  
	  Case "Call"
		mySQL="select * from users where phone_number ='" & request("session.calledid") & "'"
		  
		set rstemp=conntemp.execute(mySQL)
		
		emptyvariable = ""
		vmnumber      = rstemp("voicemail_number")
		
		if vmnumber <> "" then
		  response.write "<call value=""" & vmnumber & """ maxtime=""30s"" />"
		  response.write "<oncallfailure>"
		  response.write "  <sendevent value=""vmCallHangup"" session=""$parentSession;""/>"
		  response.write "  <hangup/>"
		  response.write "</oncallfailure>"
		  response.write "<onmaxtime>"
		  response.write "  <sendevent value=""vmCallHangup"" session=""$parentSession;""/>"
		  response.write "  <hangup/>"
		  response.write "</onmaxtime>"
		  response.write "<onanswer>"
		  response.write "  <sendevent value=""vmConferenceMe"" session=""$parentSession;""/>"
		  response.write "  <wait value=""Unlimited""/>" 
		  response.write "</onanswer>"
		  response.write "<onexternalevent value=""kill"">"
		  response.write "  <hangup/>"
		  response.write "</onexternalevent>"
		else
		  response.write "<goto value=""$rootdir;/fm2_Call_and_VM.asp?Action=NotAvailable"" submit=""*"" method=""get""/>"				
		end if
		
		rstemp.close
		set rstemp=nothing  

	  '---- ---------------------------------------------------------------
	  
	  Case "NoAnswer"
		
		mySQL="select * from users where phone_number =" 
		if request("session.calledid") = "" then
		  mySQL = mySQL & "'-1'"
		else
		  mySQL = mySQL & "'" & request("session.calledid") & "'"
		end if
		
		set rstemp=conntemp.execute(mySQL)
		  
		if rstemp.eof then
		  response.write "  <goto value=""$rootdir;/fm2_call_and_VM.asp?Action=NotAvailable"" submit=""*"" method=""get"" /> "
		else
		  if DirectToVM then
		    response.write "  <goto value=""$rootdir;/fm2_call_and_VM.asp?Action=SendToVM"" submit=""*"" method=""get"" /> "
		  else
		    response.write "  <goto value=""$rootdir;/fm2_call_and_VM.asp?Action=NoVMonNoAnswer"" submit=""*"" method=""get"" /> "
		  end if
		end if   
		
		rstemp.close
		set rstemp=nothing  
	  
	  '---- ---------------------------------------------------------------
	  
	  Case "NoVMonNoAnswer"
	    response.write "<simline value=""About to tell the caller that the user is not available""/>"
		response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/UserNotAvailable.wav""/>"
		response.write "<hangup/>"
	  
	  '---- ---------------------------------------------------------------
	  
	  Case "SendToVM"
		
		mySQL="select * from users where phone_number =" 
		if request("session.calledid") = "" then
		  mySQL = mySQL & "'-1'"
		else
		  mySQL = mySQL & "'" & request("session.calledid") & "'"
		end if
		
		set rstemp=conntemp.execute(mySQL)
		  
		if rstemp.eof then
		  response.write "  <goto value=""$rootdir;/fm2_call_and_VM.asp?Action=NotAvailable"" submit=""*"" method=""get"" /> "
		else
		  vmnumber = rstemp("voicemail_number")
		  
		  if (IsNumeric(vmnumber)) Then
  		    response.write "<block label=""fm2_send_to_vm"">" & _
		                   "  <!-- direct caller to user's voicemail -->" & _
		                   "  <simline value=""fm2_send_to_vm""/>" & _
					       "  <assign var=""parentSession"" value=""$session.ID;""/>" &_
		                   "  <block>" & _
		                   "    <run value=""$rootdir;/fm2_call_and_vm.asp?Action=Call"" submit=""*"" method=""get"" var=""vmCallSessionID""/> " & _
		                   "    <playaudio value=""$audiorootdir;/holdmusic.wav""/>" &_
		                   "    <onexternalevent value=""vmConferenceMe"">" & _
		                   "      <conference targetsessions=""$session.eventsenderID;""/>" &_
					       "      <hangup/>" & _
		                   "    </onexternalevent>" & _
		                   "    <onexternalevent value=""vmCallHangup"">" & _
					       "      <playaudio format=""audio/wav"" value=""$rootdir;/vmna.wav""/>" & _
		                   "      <hangup/>" & _
		                   "    </onexternalevent>" & _						   
					       "    <onhangup>" & _
					       "      <simline value=""About to kill the VM session $vmCallSessionID;.""/>" & _
					       "      <sendevent value=""kill"" session=""$vmCallSessionID;""/>" & _
					       "    </onhangup>" &_
		                   "  </block>" & _  
		                   "</block>"
		  elseif (vmnumber = "") Then
		    response.write "  <goto value=""$rootdir;/fm2_call_and_VM.asp?Action=NotAvailable"" submit=""*"" method=""get"" /> "
          else
            response.write "<block>" &_
			               "  <playaudio value=""$audiorootdir;/voicemailmessage.wav""/>" &_
			               "  <recordaudio format=""audio/wav"" " &_
				           "               value=""mailto:" & vmnumber & """ " &_
				           "               termdigits=""#"" " &_
				           "               maxtime=""180s"" " &_
				           "               maxsilence=""10s"" " &_
				           "               beep=""TRUE""/>" &_				
				           "  <ontermdigit value=""#"">" &_
			               "    <playaudio value=""$audiorootdir;/yourmessagehasbeensaved.wav""/>" &_
				           "  </ontermdigit>" &_
				           "  <onmaxtime>" &_
			               "    <playaudio value=""$audiorootdir;/yourmessagehasbeensaved.wav""/>" &_
				           "  </onmaxtime>" &_
				           "  <onmaxsilence>" &_
			               "    <playaudio value=""$audiorootdir;/yourmessagehasbeensaved.wav""/>" &_
				           "  </onmaxsilence>" &_
						   "  <onerror>" &_
			               "    <playaudio value=""$audiorootdir;/errorduringsave.wav""/>" &_
						   "  </onerror>" &_
						   "  <onhangup/>" &_
   			               "</block>"		    
		  end if
		end if  
		
		rstemp.close
		set rstemp=nothing  
	  
	  '---- ---------------------------------------------------------------
	  
	  Case "NotAvailable"
		response.write "<!-- user's voicemail was unavailable -->"   
		response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/vmna.wav""/>"
		response.write "<hangup/>"
	  
	End Select
	
  call WriteFooters
  call CloseDatabase
  
  
  '---- ------------------------------------------------------------------------------
  
  
  Function DirectToVM
  
    rstemp.close
    set rstemp=nothing
    mySQL="select * from users where phone_number =" & "'" & request("session.calledid") & "'" 
    set rstemp=conntemp.execute(mySQL)

    DirectToVM=rstemp("VM_on_No_answer")
    
  End Function  
%>
