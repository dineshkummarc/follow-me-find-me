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
  
  '-------------------------------------------------
  ' If this is the first pass through the file then
  ' we need to prompt the user with the main message
  ' otherwise, we have to actually add the number
  '-------------------------------------------------
  
  if request.QueryString("AddNumber") = "YES" then
    Dim conntemp
    call OpenDatabase 

    call AddNumber

    call CloseDatabase
  else
    '-----------------------------------------------
    ' First we get the new phone number to be added.
	'-----------------------------------------------
  
    response.write "<inputDigits" & vbCrLf & _
      	            "repeat=""3""" & vbCrLf & _
	    			"var=""new_number""" & vbCrLf & _
					"format=""audio/wav""" & vbCrLf & _
					"value=""$audiorootdir;/enterNewNumber.wav""" & vbCrLf & _
					"termdigits=""#""" & vbCrLf & _
					"cleardigits=""TRUE""" & vbCrLf & _
      				"includeTermDigits=""TRUE""" & vbCrLf & _
					"maxDigits=""20""" & vbCrLf & _
      				"maxtime=""15s""" & vbCrLf & _
      				"maxsilence=""5s"" >"
					
    response.write "<ontermdigit value=""#"">" +_
                   "  <goto value=""#SecondNumber""/>" +_
				   "</ontermdigit>"
	
    response.write "<onmaxtime/>"
	response.write "<onmaxdigits>" +_
                   "  <goto value=""#SecondNumber""/>" +_
				   "</onmaxdigits>"
    response.write "<onmaxsilence/>"
    response.write "</inputDigits>"
	
    response.write "<goto value=""$rootdir;/fm2_admin_number_config.asp"" submit=""*"" method=""get"" />"
	
	'---------------------------------------------------------
	' Then we get the position in the list for the new number.
	'---------------------------------------------------------
	
    response.write "<inputDigits" & vbCrLf & _ 
      	            "label=""SecondNumber""" & vbCrLf & _
      	            "repeat=""3""" & vbCrLf & _
	    			"var=""ToPos""" & vbCrLf & _
					"format=""audio/wav""" & vbCrLf & _				
					"value=""$audiorootdir;/enterOrder.wav""" & vbCrLf & _
					"termdigits=""#""" & vbCrLf & _
					"cleardigits=""TRUE""" & vbCrLf & _
      				"includeTermDigits=""FALSE""" & vbCrLf & _
					"maxDigits=""20""" & vbCrLf & _
      				"maxtime=""15s""" & vbCrLf & _
      				"maxsilence=""5s"" >"
					
    response.write "<ontermdigit value=""#""/>"
    response.write "<onmaxtime/>"
	response.write "<onmaxdigits/>"
    response.write "<onmaxsilence/>"
    response.write "</inputDigits>"
	
	'-----------------------------------------------------------
	' Hop back to this same file with the AddNumber=YES variable
	' so that the number can actually be physically saved.
	'-----------------------------------------------------------
	
	response.write "<goto value=""$rootdir;/fm2_admin_add_number.asp?AddNumber=YES"" submit=""*"" method=""get"" />"
  end if
  
  call WriteFooters
  
  '-----------------------------------------------------------------------------------

  Sub AddNumber
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
	
	'------------------------------------------------------------
	' Get userID for current user, which is based on the calledid
	' passed via the AGS.
	'------------------------------------------------------------
	
	mySQL = "select ID from users where phone_number='" & request("session.calledid") & "'"
    set rstemp=conntemp.execute(mySQL)
    lUserID = rstemp("ID")
    rstemp.close
    set rstemp=nothing  

	'------------------------------------------------------------------	   
    ' Get max order num and make sure that ToPos is not greater than it
	'------------------------------------------------------------------
	
    mySQL = "select * from fm2_numbers where user_id=" & lUserID & " order by num_Order desc"
    set rstemp=conntemp.execute(mySQL)

	'------------------------------------------------------------------------------------ 
    ' just go ahead and make the position 1 if there are no other numbers in the database
	'------------------------------------------------------------------------------------
			
	if not rstemp.EOF then
	  temp = rstemp("num_Order") + 1
      if Cint(ToPos) > CInt(temp) then
        ToPos = temp
      end if
      rstemp.close
      set rstemp=nothing  
	else
	  ToPos = 1
	  temp  = 1
	end if

    fromPos = temp
	
    '-------------------------------------------------------------------------------
    ' make sure that new_Number does not contain invalid digits and is nonzero length
	'-------------------------------------------------------------------------------
	
    newNumber = request("new_number")
    p = instr(newNumber, "*")
	
	if p > 0 then
	  response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/invalidNumber.wav""/>"
	  response.write "<goto value=""$rootdir;/fm2_admin_add_number.asp"" submit=""*"" method=""get"" />"
	else 
      '-------------------------------------
	  ' Write the new number to the database
	  '-------------------------------------
	
      MySQL = "insert into fm2_numbers(User_ID, num_Order, dial_number, enabled)"
   
      MySQL = MYSQL & " values(" & lUserID & "," & FromPos & ",'" & newNumber & "',TRUE)"
      set rstemp = conntemp.execute(MySQL)
      set rstemp = nothing  
	
  	  '-----------------------------------------------------------------
	  ' Below, we have to shuffle the number sequences around if the new
	  ' number is being put in the position of one of the old numbers
	  '-----------------------------------------------------------------

      if (cint(FromPos) = cint(ToPos)) and (FromPos <> 1) then
        response.write "<!-- Do nothing in this instance -->"
      elseif cint(FromPos) < cint(ToPos) then
	    '------------------------------------
	    ' Bump all the numbers up in the list
	    '------------------------------------
	  
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
	    '--------------------------------------
	    ' Bump all the numbers down in the list
	    '--------------------------------------
	  	
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
	  
      response.write "  <playaudio format=""audio/wav"" value=""$audiorootdir;/numberadded.wav"" />"
      response.write "  <goto value=""$rootdir;/fm2_admin_number_config.asp"" submit=""*"" method=""get"" /> "
	  
	end if
    '--------------------------------------------------------------------
        
  End Sub
%>