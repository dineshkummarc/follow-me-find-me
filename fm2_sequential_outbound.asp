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
  Call OpenDatabase
  mySQL="select * from users where phone_number ='" & request("session.calledid") & "'"
  
  set rstemp=conntemp.execute(mySQL)
  if rstemp.eof then
    readback     = FALSE
	verification = FALSE
  else
    readback     = rstemp("PIN_readback")
	verification = rstemp("PIN_verification")
	PIN          = rstemp("PIN")
  end if
  
  CurrentNumber = request("CurrentNumber")
  
  Call WriteHeaders
  
  if request("PINVerified") = "YES" then
    HoppingFromOtherFile = "YES"
    call OutboundDecision
  elseif request("PINVerified") = "NO" then
    HoppingFromOtherFile = "YES"  
    call PINVerification
  else 
    HoppingFromOtherFile = "NO"
    Call OutboundSetup
  end if
  
  rstemp.close
  set rstemp=nothing
    
  Call CloseDatabase  
  Call WriteFooters  

'-------------------------------------------------------------------------------------
  
sub OutboundSetup
  response.write "<!-- executing sequential mode dialing -->"
		
  mySQL="select * from users where phone_number =" 
  
  if request("session.calledid") = "" then
    mySQL = mySQL & "'-1'"
  else
    mySQL = mySQL & "'" & request("session.calledid") & "'"
  end if
		
  set rstemp=conntemp.execute(mySQL)
		  
  if rstemp.eof then
    response.write "<goto value=""$rootdir;/fm2_Call_and_VM.asp?Action=NotAvailable"" submit=""*"" method=""get"" />"
  else
	Fm2SQL = "select * from fm2_numbers where user_ID in (" 
	Fm2SQL = FM2SQL & "select ID from users where phone_number ='" & _
			 request("session.calledid") & "') AND enabled=TRUE order by num_Order asc"
			   
	set rsFM2Numbers = conntemp.execute(Fm2SQL)
	
	'-------------------------------------------------------------
	' We need to return to the current number that we are calling.
	' If PIN verification is turned on, then we will have to jump
	' in and out of this file. 
	'-------------------------------------------------------------
	
	if CurrentNumber <> "" then
	  NumberIsFound = FALSE
	  
	  Do Until NumberIsFound
	    if rsFM2Numbers.EOF then
		  NumberIsFound = TRUE
		elseif CurrentNumber = rsFM2Numbers("dial_number") then
		  NumberIsFound = TRUE
		else
	      rsFM2Numbers.MoveNext
		end if
	  Loop
	  
	  if NOT rsFM2Numbers.EOF then 
	    rsFM2Numbers.MoveNext
	  end if 
	  
	  response.write "<clear var=""CurrentNumber""/>"
	end if
	
	'------------------------------------------
	' Now we go through the calls that are left
	'------------------------------------------
		
	Do Until rsFM2Numbers.EOF
	  response.write "<block label=""SequentialFM2"" cleardigits=""TRUE"">" + _
	                 "<call value=""" & rsFM2Numbers("dial_number") & """ maxtime=""30s""/>"      + _
	                 "  <onanswer>" + _
					 "     <block label=""loop"" repeat=""3"" cleardigits=""false"">" + _ 
					 "       <playaudio format=""audio/wav"" " + _ 
					 "		           value=""$audiorootdir;/YouHaveCall.wav"" " + _ 
					 "				   termdigits=""12""/>" + _ 
					 "		<playnumber format=""digits"" " + _
					 "				    value=""$session.callerid;"" " + _
					 "					termdigits=""12""/>"
					
	  
	  if verification then 
	    CurrentNumber = rsFM2Numbers("dial_number")	  
        call PINVerification
      else 		 
	    call OutboundDecision	
	  end if
	
	  rsFM2Numbers.MoveNext 
	Loop 
	
	response.write "<block label=""SequentialFM2-NoAnswer"" cleardigits=""TRUE"">" + _
	              "  <sendEvent session=""$parentSession;"" value=""noAnswer""/>" + _
	              "</block>"
	
	rsFM2Numbers.close
	set rsFM2Numbers=nothing
	end if    
End Sub

'---------------------------------------------------------------------------------------

Sub OutboundDecision
   if HoppingFromOtherFile = "YES" then
     response.write "<block>"
   end if 
   
   response.write "        <playaudio format=""audio/wav"" " + _ 
				  "		           value=""$audiorootdir;/CallAcceptanceMenu.wav"" " + _
				  "				   termdigits=""12""/>" + _         
				  "		<ontermdigit value=""1"">" + _ 
				  "		  <sendEvent session=""$parentSession;"" value=""conferenceMe""/>" + _ 
				  "		  <wait value=""unlimited""/>" + _
				  "		</ontermdigit>" + _
				  "        <ontermdigit value=""2"">" + _ 
				  "		  <sendEvent session=""$parentSession;"" value=""sendtovm""/>" + _ 
				  "		  <hangup/>" + _
				  "		</ontermdigit>" + _
				  "      </block>"
				  
	if HoppingFromOtherFile = "NO" then
	  response.write "  </onanswer>"  + _
				     "  <oncallfailure/>" + _
				     "  <onmaxtime/>" + _
				     "  <onerror/>" + _
					 "  <onexternalevent value=""kill"">" + _
					 "    <hangup/>" + _
					 "  </onexternalevent>" + _
					 " </block>"
	end if
End Sub

'---------------------------------------------------------------------------------------

Sub PINVerification
  if request("admin_retries") > 2 then
    response.write "  <block label=""PINFailed"" cleardigits=""true""> " + _
                   "    <playaudio format=""audio/wav"" value=""$audiorootdir;/PINFailed.wav""/>" + _
				   "    <sendevent session=""$parentSession;"" value=""DummyEvent""/>" + _
                   "    <hangup/>" + _
                   "  </block>"
  else
    '-----------------------------------------------------------------
    ' Must keep track of which number in the sequential list we are at
	'-----------------------------------------------------------------
	
	if CurrentNumber = "" then
	  response.write "<assign var=""CurrentNumber"" value=""" & CurrentNumber & """/>"
	end if
	
    response.write "  <block label=""verifyPIN"" clearDigits=""TRUE"">" 
    if request("admin_retries") < 1 then
      response.write "  <assign var=""admin_retries"" value=""0""/> "
    end if
	
    response.write "    <!-- play PIN prompt -->" + _
                   "    <inputDigits repeat=""3"" var=""PIN"" format=""audio/wav"" maxDigits = ""6"" "  + _
                   "               value=""$audiorootdir;/enterPIN.wav"" termdigits=""#"" cleardigits=""TRUE"" " + _
                   "               includeTermDigits=""FALSE"" maxtime=""30s"" maxsilence=""5s"" > " + _
                   "      <ontermdigit value=""#""> "

    if readback then
      response.write "    <block label=""PINreadback"" repeat=""3"" cleardigits=""true""> " + _
                     "      <playaudio format=""audio/wav"" value=""$audiorootdir;/youEntered.wav"" termDigits=""12""  />" + _
                     "      <playNumber format=""digits"" value =""$PIN;"" termDigits=""12""  />" + _   
                     "      <playaudio format=""audio/wav"" value=""$audiorootdir;/PINReadbackMainMenu.wav"" termDigits=""12""  />" + _
                     "        <ontermdigit value=""1""> " +_
                     "          <goto value=""$rootdir;/fm2_admin_verify_PIN.asp?Destination=Sequential"" submit=""*"" method=""get"" /> " + _
                     "        </ontermdigit> " + _
                     "        <ontermdigit value=""2""> " + _
			         "          <goto value=""#verifyPIN"" submit=""*"" method=""get"" />" +_
			         "        </ontermdigit> " + _
                     "    </block>"
    else

      response.write "    <goto value=""$rootdir;/fm2_admin_verify_PIN.asp?Destination=Sequential"" submit=""*"" method=""get"" /> " 
    end if
    response.write "      </ontermdigit> <onmaxtime/> <onmaxsilence/>" + _
 				   "      <onmaxdigits> " + _
			       "        <goto value=""$rootdir;/fm2_admin_verify_PIN.asp?Destination=Sequential"" submit=""*"" method=""get"" />" +_
			       "      </onmaxdigits>" + _
                   "    </inputDigits>" + _
                   "  </block>"
	
	if HoppingFromOtherFile = "NO" then
	  response.write "</block>" + _
				     "</onanswer>" + _
				     "  <oncallfailure/>" + _
				     "  <onmaxtime/>" + _
				     "  <onerror/>" + _
					 "  <onexternalevent value=""kill"">" + _
					 "    <hangup/>" + _
					 "  </onexternalevent>" + _
				     "</block>"
	end if
  end if

End Sub

%>
