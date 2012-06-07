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
  
  '---------------------------------------------------------
  ' Like many of the FM2 files, we run through the same file
  ' multiple times, corresponding to multiple steps in the 
  ' process involved.  In this case, we have to prompt the
  ' user for the number to change to, and then we have to
  ' actually do the database change itself.  We do this by
  ' passing along the variable "ChangeNumber".
  '---------------------------------------------------------
  
  if request.QueryString("ChangeNumber") = "YES" then
    Dim conntemp
	Call OpenDatabase
	
    call changeNumber
	
	call CloseDatabase
  else
    call ChangeNumberMain
  end if
  
  call WriteFooters
  
  '----------------------------------------------------------------------------
  
  Sub ChangeNumberMain
    '--------------------------------------------------------------
    ' Some error checking in case the number list is empty.
	' If it is empty, then return to the number configuration menu.
	'--------------------------------------------------------------
	
    if request("current_number_id") = 0 then
	  response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/noCurrentNumber.wav""/>"
	  response.write "<goto value=""$rootdir;/fm2_admin_number_config.asp"" method=""get"" submit=""*"" />"
	else
	  '--------------------------------------------------------------------------
	  ' Get the new number and then call this file again to save the information.
	  '--------------------------------------------------------------------------
	 
	  response.write "<block label=""newNumber"" repeat=""3"">"
	     response.write "<inputDigits" & vbCrLf & _
						 "format=""audio/wav"""  & vbCrLf & _ 
						 "value=""$audiorootdir;/enterNewNumber.wav""" & vbCrLf & _ 
						 "termdigits=""#""" & vbCrLf & _ 
	      				 "cleardigits=""TRUE""" & vbCrLf & _
						 "includeTermDigits=""FALSE""" & vbCrLf & _ 
						 "maxtime=""15s""" & vbCrLf & _
						 "maxsilence=""5s""" & vbCrLf & _ 
						 "var=""new_number""" & vbCrLf & _ 
						 "maxdigits=""20"">"
	
	    response.write "<ontermdigit value=""#"">" 
	      response.write "<goto value=""$rootdir;/fm2_admin_change_number.asp?ChangeNumber=YES"" submit=""*"" method=""get"" />"
	    response.write "</ontermdigit>"
		
		'----------------------------------------------------
		' Do nothing (i.e., hangup) on maxtime or maxsilence.
		'----------------------------------------------------
		
	    response.write "<onmaxtime/>"
	    response.write "<onmaxsilence/>"
		response.write "</inputDigits>"
	  response.write "</block>"
	  response.write "<goto value=""$rootdir;/fm2_admin_number_config.asp"" method=""get"" submit=""*"" />"
	end if
  End Sub
  
  '-----------------------------------------------------------------------------------------
  
  Sub changeNumber
    '----------------------------------------------------
    ' Some error checking to make sure an enormous number
	' is not being sent in.
	'----------------------------------------------------

	currentNumberID = request("current_number_id")
    newNumber = request("new_number")
    p = instr(newNumber, "*")
	
    if (len( newNumber ) < 20) AND (p = 0) AND (len( newNumber ) > 0 ) AND ( currentNumberID <> "") then
	  '--------------------------------------------------
	  ' Update the database to reflect the number change.
	  '--------------------------------------------------
	  
      mySQL= "update fm2_numbers set dial_number='" & newNumber & "' where id=" & request("current_number_id")
      set rstemp=conntemp.execute(mySQL)
      set rstemp=nothing
    
      response.write "  <playaudio format=""audio/wav"" value=""$audiorootdir;/fm2numberChanged.wav""/>" + _
                     "  <goto value=""$rootdir;/fm2_admin_number_config.asp"" submit=""*"" method=""get"" />"
	else
	  response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/invalidNumber.wav""/>"
	  response.write "<goto value=""$rootdir;/fm2_admin_change_number.asp"" submit=""*"" method=""get"" />"
	end if
  End Sub
%>

