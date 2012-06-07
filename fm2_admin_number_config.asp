<%@ LANGUAGE = VBScript %>

<!-- #include file="subs.asp" -->

    <%
  ' ---------------------------------------------------
  ' copyright 2000 by voxeo corporation. (see LGPL.txt)
  '
  ' v1.0 Coded in ASP
  ' v1.0 Coded by Ryan Campbell and Stephen J. Lewis
  ' ---------------------------------------------------
  
	  response.write "<?xml version=""1.0"" encoding=""UTF-8""?>"
	  response.write "<callxml>"
	  response.write "<block label=""numberConfig"" repeat=""3"" cleardigits=""TRUE"">"
	
	  on Error resume next
	  
	  Dim conntemp
	  call OpenDatabase
  
      localid = ""
      if request("current_number_id") = 0 then
        mySQL="select id from fm2_numbers where user_id = (select id from users where phone_number ='" & request("session.calledid") & "') order by num_Order asc"
        set rstemp=conntemp.execute(mySQL)
        response.write "<assign var=""current_number_id"" value=""" & rstemp("id") & """ /> "
		localid = rstemp("id")
		
    	rstemp.close
	    set rstemp=nothing
	  end if
    
	  if localid = "" then
	    mySQL="select * from fm2_numbers where ID =" & request("current_number_id")
	  else  
	    mySQL="select * from fm2_numbers where ID =" & localID	    
	  end if
	  set rstemp=conntemp.execute(mySQL)
	    
	  if not rstemp.eof then
	    response.write "<assign var=""currentNumber"" value=""" & rstemp("dial_number") & """ />"
	  end if

      response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/numberConfigAnnounce.wav"" " +_
			 	     "termdigits=""123456789*""/>"
	  
	  if rstemp("dial_number") = "" then
	    response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/noNumbersInList.wav""/>"
	  else
	    response.write "<playnumber format=""digits"" value=""$currentNumber;"" termdigits=""123456789*""/>"
	  
	  end if
	
	  rstemp.close
	  set rstemp=nothing  
	  
	  call CloseDatabase 
	   
	%>
	
    <playaudio format="audio/wav" value="$audiorootdir;/numberConfig.wav" termdigits="123456789*"/>
	
    <ontermdigit value="1"> 
      <goto value="$rootdir;/fm2_admin_change_number.asp" submit="*" method="get" /> 
    </ontermdigit> 
    <ontermdigit value="2"> 
      <goto value="$rootdir;/fm2_admin_add_number.asp" submit="*" method="get" /> 
    </ontermdigit> 
    <ontermdigit value="3"> 
      <goto value="$rootdir;/fm2_admin_delete_number.asp" submit="*" method="get" /> 
    </ontermdigit> 
    <ontermdigit value="4"> 
      <assign var="direction" value="back"/>
      <goto value="$rootdir;/fm2_admin_move.asp" submit="*" method="get" /> 
    </ontermdigit> 
    <ontermdigit value="5"> 
      <assign var="direction" value="forward"/>
      <goto value="$rootdir;/fm2_admin_move.asp" submit="*" method="get" /> 
    </ontermdigit>
    <ontermdigit value="6"> 
      <goto value="$rootdir;/fm2_admin_change_order.asp" submit="*" method="get" /> 
    </ontermdigit> 
    <ontermdigit value="7"> 
      <assign var="direction" value="first"/>
      <goto value="$rootdir;/fm2_admin_move.asp" submit="*" method="get" /> 
    </ontermdigit>
    <ontermdigit value="8"> 
      <assign var="direction" value="last"/>
      <goto value="$rootdir;/fm2_admin_move.asp" submit="*" method="get" /> 
    </ontermdigit>
    <ontermdigit value="9"> 
      <goto value="$rootdir;/fm2_admin_enable.asp?Enable=Number" submit="*" method="get" /> 
    </ontermdigit> 
    <ontermdigit value="*"> 
      <goto value="$rootdir;/fm2_admin_menu.xml" submit="*" method="get" /> 
    </ontermdigit> 
  </block> <!-- numberConfig -->
</callxml>
