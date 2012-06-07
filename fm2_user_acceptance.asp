<%@ LANGUAGE = VBScript %>

<!-- #include file="subs.asp" -->

<%
  ' ---------------------------------------------------
  ' copyright 2000 by voxeo corporation. (see LGPL.txt)
  '
  ' v1.0 Coded in ASP
  ' v1.0 Coded by Ryan Campbell and Stephen J. Lewis
  ' ---------------------------------------------------
  
  call WriteHeaders
  
  Dim conntemp
  Call OpenDatabase
  
  Action = Request.QueryString("UserAcceptance")
    Select Case Action
	  Case "Menu"
		mySQL="select * from users where phone_number ='" & request("session.calledid") & "'"
		
		set rstemp=conntemp.execute(mySQL)

		call AcceptanceMenu

		rstemp.close
		set rstemp=nothing    
	  
	  '---- ------------------------------------------------
	  
	  Case "VerifyPIN"
		mySQL="select * from users where phone_number ='" & request("session.calledid") & "'"
		
		set rstemp=conntemp.execute(mySQL)
		
		if rstemp("PIN") = request("PIN") then
		response.write "  <goto value=""$rootdir;/fm2_user_acceptance.asp?UserAcceptance=Menu"" submit=""*"" method=""get"" /> "
		else
		response.write "  <goto value=""$rootdir;/fm2_call_and_VM.asp?Action=SendToVM"" submit=""*"" method=""get"" /> "
		end if
		
		rstemp.close
		set rstemp=nothing    
	  
	  '---- ------------------------------------------------
	  
	  Case Else
		  
		call CallAcceptance
		
 
	End Select
	
  call WriteFooters	
  
  call CloseDatabase	
	
  '---- ------------------------------------------------------------------------
	
  Sub CallAcceptance
    response.write "<!-- play caller ID -->" 
		
	mySQL="select * from users where phone_number ='" & request("session.calledid") & "'"
		
    set rstemp=conntemp.execute(mySQL)	
  
    ' response.write rstemp("PIN_verification")
	
    if not(rstemp("PIN_verification")) then
      response.write "  <goto value=""fm2_user_acceptance.asp?UserAcceptance=Menu"" submit=""*"" method=""get""/>"
    else
      response.write "    <!-- play PIN prompt -->" + _
                     "  <block label=""verifyPIN"">" + _
                     "  <inputDigits format=""audio/wav"" var=""PIN"" " + _
                     "               value=""$audiorootdir;/enterPIN.wav"" " + _
                     "               maxDigits = ""6"" " + _
                     "		     termDigits = ""#"" " + _
                     "		     includeTermDigit = ""false"" " + _
                     "               cleardigits=""true"" " + _
                     "		     maxtime = ""30s"" " + _
                     "		     maxsilence = ""10s"" >"
      	
      if rstemp("PIN_readback") then
        response.write "    <block label=""PINreadback"" repeat=""3"" cleardigits=""true"" maxtime=""10s""> " + _
                       "      <playaudio format=""audio/wav"" value=""$audiorootdir;/youEntered.wav"" termDigits=""12""  />" + _
                       "      <playNumber format=""digits"" value =""$PIN;"" termDigits=""1,2""  />" + _   
                       "      <playaudio format=""audio/wav"" value=""$audiorootdir;/PINreadbackmenu.wav"" termDigits=""12""  />" + _
                       "      <ontermdigit value=""1""> <goto value=""$rootdir;/fm2_user_acceptance.asp?UserAcceptance=VerifyPIN"" submit=""*"" method=""get"" /> </ontermdigit> " + _
                       "      <ontermdigit value=""2""> <goto value=""#verifyPIN"" submit=""*"" method=""get"" /> </ontermdigit> " + _
                       "    <!-- if we get out of the above loop then verify the last PIN entered -->" + _
                       "    <goto value=""$rootdir;/fm2_user_acceptance.asp?UserAcceptance=VerifyPIN"" submit=""*"" method=""get""/>" + _
                       "    </block>" + _
                       "    <ontermdigit/>"
      else
        response.write "    <ontermdigit> <goto value=""$rootdir;/fm2_user_acceptance.asp?UserAcceptance=VerifyPIN"" submit=""*"" method=""get""/> </ontermdigit>"	    
      end if
      
      response.write "    <onmaxtime/>" + _
                     "    <onmaxsilence/>" + _
                     "  </inputDigits>" + _ 
                     "  </block>"
    end if
	
	rstemp.close
	set rstemp=nothing 
  
  End Sub
  
  '---- -----------------------------------------------------------------------
  
  Sub AcceptanceMenu
    response.write "<block  label=""acceptance_menu""> " + _
                   "  <block label=""loop"" repeat=""3"" cleardigits=""false"" maxtime=""20s""> " + _
                   "    <playaudio format=""audio/wav"" value=""$audiorootdir;/YouHaveCall.wav"" termdigits=""12"" cleardigits=""true"" />" + _
                   "    <playaudio format=""audio/wav"" value=""$audiorootdir;/CallAcceptanceMenu.wav"" termdigits=""12"" cleardigits=""true"" />" + _
                   "    <ontermdigit value=""1""> <sendEvent session=""$parentSession;"" value=""conferenceMe""/> </ontermdigit> " + _
                   "    <ontermdigit value=""2""> <sendEvent session=""$parentSession;"" value=""sendToVM""/> <hangup/> </ontermdigit> " + _
                   "  </block>" + _
                   "<!-- if we get out of the above menu for any reason, send to no answer -->" + _
                   "  <simline value="")))out of acceptance_menu block""/> " + _
                   "  <sendEvent session=""$parentSession;"" value=""noAnswer""/> <hangup/> "+ _
                   "</block>" 
  End Sub
  
%>