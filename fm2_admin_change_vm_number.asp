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
  
  '---------------------------------------------------------------
  ' We use the variable ChangeVMNumber to determine whether we are
  ' are asking the user/caller for the new number, or actually
  ' making the database change (in other words, pass 1 or pass 2).
  '----------------------------------------------------------------
  
  if request.QueryString("ChangeVMNumber") = "YES" then
    Dim conntemp
    
	call OpenDatabase
	
	'--------------------
	' Update the database
	'--------------------
	
    mySQL= "update users set voicemail_number='" & request("new_vm_number") & "' where phone_number='" & request("session.calledid") & "'"
    set rstemp=conntemp.execute(mySQL)
    set rstemp=nothing
	
	'----------------------------------------------------------------
	' Inform the caller that their voicemail number has been
	' changed, and then send them back to the global properties menu.
	'----------------------------------------------------------------
    
    response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/numberChanged.wav""/>" + _
                   "<goto value=""$rootdir;/fm2_admin_global_properties.xml"" submit=""*"" method=""get"" />"

    call CloseDatabase
  else
%>
      <!-- ================================================= -->
      <!-- Get the new voicemail number from the caller/user -->
	  <!-- ================================================= -->
   
	  <inputDigits 
	      repeat="3" 
	      var="new_vm_number"
	      format="audio/wav"
	      value="$audiorootdir;/changeVMNumber.wav"
	      termdigits="#" 
	      cleardigits="TRUE"
	      includeTermDigits="FALSE"
	      maxDigits="20"
	      maxtime="15s"
	      maxsilence="5s" >
		  
		<!-- ============================================================= -->
		<!-- Go ahead and reload the page to save the new voicemail number -->
		<!-- on either maxdigits on the # key.  On maxtime or maxsilence,  -->
		<!-- the block is repeated.                                        -->
		<!-- ============================================================= -->
	
	    <ontermdigit value="#"> 
		  <goto value="$rootdir;/fm2_admin_change_vm_number.asp?ChangeVMNumber=YES" submit="*" method="get" /> 
		</ontermdigit> 
		
		<onmaxdigits>
		  <goto value="$rootdir;/fm2_admin_change_vm_number.asp?ChangeVMNumber=YES" submit="*" method="get" /> 	  
		</onmaxdigits>
	
	    <onmaxtime/>
	    <onmaxsilence/>
	  </inputDigits>
	  
	  <goto value="$rootdir;/fm2_admin_global_properties.xml" submit="*" method="get" />
<%
  end if  
  
  
  Call WriteFooters
%>

