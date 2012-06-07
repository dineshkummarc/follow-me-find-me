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
  Dim conntemp, rstemp
  call OpenDatabase  
  call DoMove
  
  response.write "  <goto value=""$rootdir;/fm2_admin_number_config.asp"" submit=""*"" method=""get"" /> "  
  
  call CloseDatabase  
  Call WriteFooters

  Sub DoMove 
  
    DontClearObject = "" 

    if request("current_number_id") = 0 then
      mySQL="select id from fm2_numbers where user_id = (select id from users where phone_number ='" & request("session.calledid") & "') order by num_order asc"
      set rstemp=conntemp.execute(mySQL)
    
      response.write "  <assign var=""current_number_id"" value=""" & rstemp("id") & """ /> " + _
                     "  <goto value=""$rootdir;/fm2_admin_move.asp"" submit=""*"" method=""get"" /> "
      rstemp.close
      set rstemp=nothing					 
    else
      if request("direction") = "forward" then
        mySQL="select id from fm2_numbers where num_order > (select num_order from fm2_numbers where id=" & request("current_number_id") & _
		      ") and user_id = (select id from users where phone_number ='" & request("session.calledid") & "')"
        set rstemp=conntemp.execute(mySQL)         
        if rstemp.eof then
          response.write "  <playaudio format=""audio/wav"" value=""$audiorootdir;/endOfList.wav"" cleardigits=""false"" /> "
        else
          response.write "  <assign var=""current_number_id"" value=""" & rstemp("id") & """ /> "     
        end if  
      elseif request("direction") = "back" then
        mySQL="select id from fm2_numbers where num_order < (select num_order from fm2_numbers where id=" & request("current_number_id") & _
		      ") and user_id = (select id from users where phone_number ='" & request("session.calledid") & "') order by num_Order desc"
        set rstemp=conntemp.execute(mySQL)
        if rstemp.eof then
          response.write "  <playaudio format=""audio/wav"" value=""$audiorootdir;/beginningOfList.wav"" cleardigits=""false"" /> "
        else
          response.write "  <assign var=""current_number_id"" value=""" & rstemp("id") & """ /> "           
        end if  
      elseif request("direction") = "first" then
        mySQL="select id from fm2_numbers where user_id = (select id from users where phone_number ='" & request("session.calledid") & "') order by num_order asc"
        set rstemp=conntemp.execute(mySQL)
        response.write "  <playaudio format=""audio/wav"" value=""$audiorootdir;/beginningOfList.wav"" cleardigits=""false"" /> "
        if not rstemp.eof then
          response.write "  <assign var=""current_number_id"" value=""" & rstemp("id") & """ /> "           
        end if  
      elseif request("direction") = "last" then
        mySQL="select id from fm2_numbers where num_order > (select num_order from fm2_numbers where id=" & request("current_number_id") & _
			  ") and user_id = (select id from users where phone_number ='" & request("session.calledid")  & "') order by num_Order desc"
        set rstemp=conntemp.execute(mySQL)
        response.write "  <playaudio format=""audio/wav"" value=""$audiorootdir;/endOfList.wav"" cleardigits=""false"" /> "
        if not rstemp.eof then
          response.write "  <assign var=""current_number_id"" value=""" & rstemp("id") & """ /> "           
        end if  
      else
        response.write "<!-- invalid movement request -->"
		DontClearObject = "YES"    
      end if
	  
	  if DontClearObject <> "YES" then
	    rstemp.close
        set rstemp=nothing
	  end if
    end if  
  


    
  End Sub
%>

