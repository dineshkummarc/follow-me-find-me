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
  ' user for the order to change to, and then we have to
  ' actually do the database change itself.  We do this by
  ' passing along the variable "ChangeOrder".
  '---------------------------------------------------------  
  
  if request.QueryString("ChangeOrder") = "YES" then
    If (request("ToPos") = "") Then
      response.write "  <goto value=""$rootdir;/fm2_admin_number_config.asp"" submit=""*"" method=""get"" />"  	  
	Else
      Dim conntemp
	
  	  call OpenDatabase 
      call MoveNumber
      call CloseDatabase
	End If
  else
    call MoveNumberMain
  end if
  
  call WriteFooters
  
  '--------------------------------------------------------------------------
  
  Sub MoveNumberMain
    '---------------------------------------------------
    ' Get the new position/order for the current number.
	'---------------------------------------------------
	
    response.write "<inputDigits" & vbCrLf & _
      				"repeat=""3""" & vbCrLf & _
					"var=""ToPos""" & vbCrLf & _
					"format=""audio/wav""" & vbCrLf & _
					"value=""$audiorootdir;/enterNewOrder.wav""" & vbCrLf & _
					"termdigits=""#""" & vbCrLf & _
					"cleardigits=""TRUE""" & vbCrLf & _
      				"includeTermDigits=""FALSE""" & vbCrLf & _
      				"maxdigits=""6""" & vbCrLf & _
					"maxtime=""15s""" & vbCrLf & _
      				"maxsilence=""5s"" >"
					
    response.write "<ontermdigit value=""#""/>"
    response.write "<onmaxtime/>"
    response.write "<onmaxsilence/>"
    response.write "</inputDigits>"
	
	'-----------------------------------------------
	' Call the same file to do the database changes.
	'-----------------------------------------------

    response.write "<goto value=""$rootdir;/fm2_admin_change_order.asp?ChangeOrder=YES"" submit=""*"" method=""get"" />"  
  End Sub
  
  '-------------------------------------------------------------------------
  
  Sub MoveNumber
    '-----------------------------------------------
    ' Get the old position (FromPos) for the number.
	'-----------------------------------------------
	
    mySQL = "select num_order from fm2_numbers where id=" & request("current_number_id") 
    set rstemp=conntemp.execute(mySQL)
    FromPos = rstemp("num_Order")
    rstemp.close
    set rstemp=nothing  

	'---------------------------------------------------------------------------
    ' make sure that ToPos does not contain invalid digits and is nonzero length
	'---------------------------------------------------------------------------
	
    ToPos = request("ToPos")
    p = instr(ToPos, "*")
	while p > 0 
	  ToPos = left(ToPos, p - 1) & right(ToPos, len(ToPos) - p)
      p = instr(ToPos, "*")
	wend
    if len(ToPos) = 0 then 
      ToPos = 1
    end if
	
    '----------------------------   
	' Get userID for current user
	'----------------------------
	
	mySQL = "select ID from users where phone_number='" & request("session.calledid") & "'"
    set rstemp=conntemp.execute(mySQL)
    lUserID = rstemp("ID")
    rstemp.close
    set rstemp=nothing
	
	'-----------------------------------------
	' Get the rest of the numbers in the list.
	'-----------------------------------------

    mySQL = "select * from fm2_numbers where user_id=" & lUserID & " order by num_Order desc"
    set rstemp=conntemp.execute(mySQL)
    temp = rstemp("num_Order")
    if Cint(ToPos) > CInt(temp) then
      ToPos = temp
    end if
    rstemp.close
    set rstemp=nothing  
	
	'--------------------------------------------------------------------
	' Now we compare the two positions of the number (FromPos and ToPos).
	' We have to shift the order if the new position falls somewhere 
	' in the middle of the list.
	'--------------------------------------------------------------------

    if cint(FromPos) = cint(ToPos) then
	  '--------------------------------------------
      ' Do nothing here, as it is the same position
	  '--------------------------------------------
    elseif cint(FromPos) < cint(ToPos) then
	  '--------------------
	  ' Bump the numbers up
	  '--------------------
	  
      mySQL = "update fm2_numbers set num_Order=-1 where num_Order=" & FromPos & " and user_id=" & lUserID
      set rstemp=conntemp.execute(mySQL)
      for i = FromPos + 1 to ToPos
        mySQL="update fm2_numbers set num_Order=" & i-1 & " where num_Order=" & i & " and user_id=" & lUserID
        set rstemp=conntemp.execute(mySQL)
      next
      mySQL = "update fm2_numbers set num_Order=" & ToPos & " where num_Order=-1 and user_id=" & lUserID    
      set rstemp=conntemp.execute(mySQL)

      set rstemp=nothing  
    else
	  '----------------------
	  ' Bump the numbers down
	  '----------------------
	  
      mySQL = "update fm2_numbers set num_Order=-1 where num_Order=" & FromPos & " and user_id=" & lUserID
      set rstemp=conntemp.execute(mySQL)
      for i = FromPos -1 to ToPos step -1
        mySQL="update fm2_numbers set num_Order=" & i+1 & " where num_Order=" & i & " and user_id=" & lUserID
        set rstemp=conntemp.execute(mySQL)
      next
      mySQL = "update fm2_numbers set num_Order=" & ToPos & " where num_Order=-1 and user_id=" & lUserID      
      set rstemp=conntemp.execute(mySQL)

      set rstemp=nothing  
    end if
	
	'-------------------------------------------------
	' Inform the caller that the number has been moved 
	' from position x to position y.  Then return to
	' the number configuration menu.
	'-------------------------------------------------

    response.write "  <playaudio format=""audio/wav"" value=""$audiorootdir;/numberMovedFrom.wav""/>" + _
                   "  <playNumber format=""digits"" value =""" & cstr(fromPos) & """/>"  + _
                   "  <playaudio format=""audio/wav"" value=""$audiorootdir;/numberMovedTo.wav""/>" + _
                   "  <playNumber format=""digits"" value =""" & cstr(toPos) & """/>"
    response.write "  <goto value=""$rootdir;/fm2_admin_number_config.asp"" submit=""*"" method=""get"" />"  
  End Sub

%>