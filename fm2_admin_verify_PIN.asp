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
  
  mySQL="select * from users where phone_number ='" & request("session.calledid") & "'"
  
  set rstemp=conntemp.execute(mySQL)
  
  if rstemp.eof then
    PIN = 0
  else 
    PIN = rstemp("PIN")
  end if
    
  call WriteHeaders
  
  if request("Destination") = "Parallel" then
    if PIN = request("PIN") then
      response.write "  <goto value=""$rootdir;/fm2_parallel_outbound.asp?PINVerified=YES"" submit=""*"" method=""get"" /> "
    else
      response.write "  <playaudio format=""audio/wav"" value=""$audiorootdir;/badPIN.wav"" clearDigits=""false"" /> " + _
                     "  <assign var=""admin_retries"" value=""" & (request("admin_retries") + 1) & """/>" + _
                     "  <goto value=""$rootdir;/fm2_parallel_outbound.asp?PINVerified=NO"" submit=""*"" method=""get"" /> "
    end if  
  elseif request("Destination") = "Sequential" then
    if PIN = request("PIN") then
      response.write "  <goto value=""$rootdir;/fm2_sequential_outbound.asp?PINVerified=YES"" submit=""*"" method=""get"" /> "
    else
      response.write "  <playaudio format=""audio/wav"" value=""$audiorootdir;/badPIN.wav"" clearDigits=""false"" /> " + _
                     "  <assign var=""admin_retries"" value=""" & (request("admin_retries") + 1) & """/>" + _
                     "  <goto value=""$rootdir;/fm2_sequential_outbound.asp?PINVerified=NO"" submit=""*"" method=""get"" /> "
    end if     
  else
    if PIN = request("PIN") then
      response.write "  <goto value=""$rootdir;/fm2_admin_menu.xml"" submit=""*"" method=""get"" /> "
    else
      response.write "  <playaudio format=""audio/wav"" value=""$audiorootdir;/badPIN.wav"" clearDigits=""false"" /> " + _
                     "  <assign var=""admin_retries"" value=""" & (request("admin_retries") + 1) & """/>" + _
                     "  <goto value=""$rootdir;/fm2_admin.asp"" submit=""*"" method=""get"" /> "
    end if
  end if

  call WriteFooters

  rstemp.close
  set rstemp=nothing  
  
  call CloseDatabase
%>