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
  
  response.write "<block>"
  
  '-----------------------------------------------------------
  ' This is a session filter script to ensure that an external
  ' event does not get sent back to the originator session, 
  ' which can interrupt a conferenced line
  '-----------------------------------------------------------

  '--------------------------------------------
  ' We only want to place the actual calls once
  '--------------------------------------------
  
  AlreadyCalled      = request("alreadycalled")
  AlreadyConferenced = request("alreadyconferenced")
  
  if AlreadyCalled <> "yes" then
    response.write "<assign var=""parentSession"" value=""$session.ID;""/>"

    Fm2SQL = "select * from fm2_numbers where user_ID in ("  +_
             "select ID from users where phone_number ='" & request("session.calledid") & "')" +_
             " AND enabled=TRUE"

    set rsFM2Numbers = conntemp.execute(Fm2SQL)

    numCalls = 0  
    Do Until rsFM2Numbers.EOF
      response.write "  <assign var=""numToDial"" value=""" & rsFM2Numbers("dial_number") & """/> " + _ 
                     "  <run value=""$rootdir;/fm2_parallel_outbound.asp"" " +_
                     "       submit=""*"" " +_
                     "       method=""get"" " +_
                     "       var=""child" & numCalls & """/> "   

	  response.write " <simline value=""child" & numCalls & " = $child" & numcalls & ";"" /> " 

      rsFM2Numbers.MoveNext
      numCalls = numCalls + 1 
    Loop 
	
    rsFM2Numbers.close
    set rsFM2Numbers=nothing  	
	
	response.write "<assign var=""TotalCalls"" value=""" & numCalls & """/>"
	response.write "<assign var=""alreadycalled"" value=""yes""/>"
	response.write "<assign var=""TotalReplies"" value=""0""/>"
	
	JustCalled = "YES"
	TotalCalls = numCalls
	
  else
    '----------------------------------------------------------------------
    ' Here we need to intelligently send events back to our genesis session
	'----------------------------------------------------------------------
    
	TotalReplies = request("TotalReplies")
    TotalCalls   = request("TotalCalls")	
	
	Select Case request("Event")
	  Case "conferenceme"
	    if AlreadyConferenced <> "yes" then
		  response.write "<simline value=""Which Session=" & request("WhichSession") & """/>"
		
	      response.write "<assign var=""alreadyconferenced"" value=""yes""/>" & _
                         "<sendEvent session=""" & request("WhichSession") & """ value=""Ready""/>"
		  AlreadyConferenced = "yes"
		  
		  '-------------------------------------------------------
		  ' Okay, this little piece of code defies the idea of a 
		  ' "session filter" because it auto kills all the other
		  ' sessions.  But, this is used so that the other phones
		  ' do not keep ringing even though a phone has already 
		  ' been conferenced.
		  '-------------------------------------------------------
		  
		  For Loopy = 0 to (request("TotalCalls") - 1)
		    Temp = request("child" & Loopy)
			
			If (Temp <> request("WhichSession")) Then
			  response.write "<simline value=""child" & Loopy & "=" & Temp & """/>"
              response.write "<sendEvent session=""" & Temp & """ value=""Kill""/>"
			End If
		  Next 
			  
		  response.write "<hangup/>"
	    end if
		
		TotalReplies = TotalReplies + 1
		response.write "<assign var=""TotalReplies"" value=""" & TotalReplies & """/>"
		
	  '----------------
		
	  Case "sendtovm"
  	    if AlreadyConferenced <> "yes" then
	      response.write "<assign var=""alreadyconferenced"" value=""yes""/>" & _
                         "<sendEvent session=""$genesisSession;"" value=""sendToVM""/>"
		  AlreadyConferenced = "yes"

		  '-------------------------------------------------------
		  ' Okay, this little piece of code defies the idea of a 
		  ' "session filter" because it auto kills all the other
		  ' sessions.  But, this is used so that the other phones
		  ' do not keep ringing even though a phone has already 
		  ' been sent to VM.
		  '-------------------------------------------------------
		  
		  For Loopy = 0 to (request("TotalCalls") - 1)
		    Temp = request("child" & Loopy)
			
			If (Temp <> request("WhichSession")) Then
			  response.write "<simline value=""child" & Loopy & "=" & Temp & """/>"
              response.write "<sendEvent session=""" & Temp & """ value=""Kill""/>"
			End If
		  Next 
			  
		  response.write "<hangup/>"
	    end if

		TotalReplies = TotalReplies + 1		
		response.write "<assign var=""TotalReplies"" value=""" & TotalReplies & """/>"
       
	  '-------------------  
		
	  Case "failure"
		TotalReplies = TotalReplies + 1	  
		response.write "<assign var=""TotalReplies"" value=""" & TotalReplies & """/>"
	  
	  '-------------------
	  
	  Case "noanswer"
	    TotalReplies = TotalCalls
		
    End Select
	
  end if
 
  if ((CInt(TotalReplies) < CInt(TotalCalls)) OR (JustCalled = "YES")) AND (CInt(TotalCalls) <> 0) then
    response.write "<block label=""parallelFM2"" repeat=""" & TotalCalls & """>" +_
                   "  <wait value=""90s""/>" +_
		           "</block>" +_

				   "  <onexternalevent value=""conferenceMe"">" +_
				   "    <goto value=""$rootdir;/fm2_parallel_sessionfilter.asp?Event=conferenceme&amp;WhichSession=$session.eventsenderid;"" submit=""*"" method=""get""/> " +_
                   "  </onexternalevent>"  + _
                   "  <onexternalevent value=""sendtovm"">" + _
				   "    <goto value=""$rootdir;/fm2_parallel_sessionfilter.asp?Event=sendtovm"" submit=""*"" method=""get""/> " +_
                   "  </onexternalevent>"  + _
                   "  <onexternalevent value=""Failure"">" + _
                   "    <goto value=""$rootdir;/fm2_parallel_sessionfilter.asp?Event=failure"" submit=""*"" method=""get""/> " +_
                   "  </onexternalevent>" + _


                   "<!-- no one answered -->" + _
                   "<goto value=""$rootdir;/fm2_parallel_sessionfilter.asp?Event=noanswer"" submit=""*"" method=""get""/> "
  else
    if Alreadyconferenced <> "yes" then
	  response.write "<assign var=""alreadyconferenced"" value=""yes""/>" & _
                     "<sendEvent session=""$genesisSession;"" value=""NoAnswer""/>"
	end if 

  end if

  response.write "</block>"
  
  response.write "  <onexternalevent value=""kill"">"
  
  '--------------------------------------------------------------
  ' TotalCalls will not be accessible from the querystring until
  ' the page reloads at least once.  If we are still sitting in
  ' the first pass through the page, then we have to use numCalls
  '--------------------------------------------------------------
  
  if request("TotalCalls") = "" then
    TempTotalCalls = numCalls
  else
    TempTotalCalls = request("TotalCalls")
  end if
  
  '------------------------------------------------
  ' Kill all the child sessions if a kill event 
  ' comes down the pipe -- that is, if the original
  ' caller hangs up.
  '------------------------------------------------
  
  For Loopy = 0 to (TempTotalCalls - 1)
    Temp = request("child" & Loopy)
	
	'--------------------------------------------------------------------------
	' We have to make this check in case the page has not reloaded itself.
	' Why?  Because the variables $child0; through $childn; are in callXML
	' until the page reloads itself, at which time they are accessible via ASP.
	'--------------------------------------------------------------------------
	
	if Temp = "" then 
	  response.write "<simline value=""child" & Loopy & " = $child" & Loopy & ";""/>"
      response.write "<sendEvent session=""$child" & Loopy & ";"" value=""Kill""/>"
    else	
	  response.write "<simline value=""child" & Loopy & "=" & Temp & """/>"
      response.write "<sendEvent session=""" & Temp & """ value=""Kill""/>"
    end if	  
  Next 
	
  response.write "  </onexternalevent>"
  
	    
  call WriteFooters
  call CloseDatabase  
%>		
