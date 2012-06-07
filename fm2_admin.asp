<%@ LANGUAGE = VBScript %>

<!-- #include file="subs.asp" -->

<%
  ' ---------------------------------------------------
  ' copyright 2000 by voxeo corporation. (see LGPL.txt)
  '
  ' v1.0 Coded in ASP
  ' v1.0 Coded by Ryan Campbell and Stephen J. Lewis
  ' ---------------------------------------------------
  
  '-------------------------------------------------------
  ' Here we allocate a database connection variable, then
  ' open up the database (from the subroutine located in
  ' subs.asp).  Everything in the database is keyed off of
  ' the calledid that the AGS passes along.
  '-------------------------------------------------------
  
  Dim conntemp
  Call OpenDatabase
  mySQL="select * from users where phone_number ='" & request("session.calledid") & "'"
  
  set rstemp=conntemp.execute(mySQL)
  
  '---------------------------------------------------
  ' We need to determine from the PIN_Readback whether
  ' to readback the PIN after the caller enters it.
  '---------------------------------------------------
  
  if rstemp.eof then
    readback = FALSE
  else
    readback = rstemp("PIN_readback")
  end if
  
  '-----------------------------------------------------------
  ' WriteHeaders and WriteFooters are in subs.asp  They simply
  ' write the opening XML and callXML tags.
  '-----------------------------------------------------------
      
  call WriteHeaders
  call Admin
  call WriteFooters
  
  '----------------------------------------------------------
  ' Clear out our database connection and close the database.
  '----------------------------------------------------------

  rstemp.close
  set rstemp=nothing
    
  Call CloseDatabase
  
  '---------------------------------------------------------------------------------------

  Sub Admin
    '---------------------------------------------
    ' Only allow 3 total attempts to enter the PIN
	'---------------------------------------------
  
    if request("admin_retries") > 2 then
      response.write "  <block label=""PINFailed"" cleardigits=""true""> " + _
                     "    <playaudio format=""audio/wav"" value=""$audiorootdir;/PINFailed.wav""/>" + _
                     "    <hangup/>" + _
                     "  </block>"
    else
      response.write "  <block label=""verifyPIN"" clearDigits=""TRUE"">" 
	  
	  '-----------------------------------------------------------------
	  ' We are using the AGS to pass the variable called "admin_retries"
	  '-----------------------------------------------------------------
	  
      if request("admin_retries") < 1 then
        response.write "    <assign var=""admin_retries"" value=""0""/> "
      end if
	  
	  '-----------------------------------
	  ' Prompt the caller to enter the PIN
	  '-----------------------------------
	  
      response.write "    <!-- play PIN prompt -->" + _
                     "    <inputDigits repeat=""3"" var=""PIN"" format=""audio/wav"" maxDigits = ""6"" "  + _
                     "               value=""$audiorootdir;/enterPIN.wav"" termdigits=""#"" cleardigits=""TRUE"" " + _
                     "               includeTermDigits=""FALSE"" maxtime=""30s"" maxsilence=""5s"" > " + _
                     "      <ontermdigit value=""#""> "

	  '------------------------------------------------------
	  ' If the user's database entry is set for PIN readback, 
	  ' then read the entered PIN to the caller before 
	  ' moving on to official verification.  Basically, it 
	  ' says "You entered 123456789...  Is this correct?"
	  '------------------------------------------------------
					 
      if readback then
        response.write "    <block label=""PINreadback"" repeat=""3"" cleardigits=""true""> " + _
                       "      <playaudio format=""audio/wav"" value=""$audiorootdir;/youEntered.wav"" termDigits=""12""  />" + _
                       "      <playNumber format=""digits"" value =""$PIN;"" termDigits=""12""  />" + _   
                       "      <playaudio format=""audio/wav"" value=""$audiorootdir;/PINReadbackMainMenu.wav"" termDigits=""12""  />" + _
                       "        <ontermdigit value=""1""> " +_
                       "          <goto value=""$rootdir;/fm2_admin_verify_PIN.asp"" submit=""*"" method=""get"" /> " + _
                       "        </ontermdigit> " + _
                       "        <ontermdigit value=""2""> " + _
					   "          <goto value=""#verifyPIN"" submit=""*"" method=""get"" />" +_
					   "        </ontermdigit> " + _
                       "    </block>"
      else
        response.write "    <goto value=""$rootdir;/fm2_admin_verify_PIN.asp"" submit=""*"" method=""get"" /> " 
      end if
	  
	  '--------------------------------------------------------
	  ' Hangup on maxtime or maxsilence, but on maxdigits, send
	  ' the entered PIN along for verification.
	  '--------------------------------------------------------
	  
      response.write "      </ontermdigit> <onmaxtime/> <onmaxsilence/>" + _
	  				 "      <onmaxdigits> " + _
					 "        <goto value=""$rootdir;/fm2_admin_verify_PIN.asp"" submit=""*"" method=""get"" />" +_
					 "      </onmaxdigits>" + _
                     "    </inputDigits>" + _
                     "  </block>" 
    end if
  End Sub
%>

