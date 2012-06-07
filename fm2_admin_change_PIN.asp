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
  ' user for the PIN to change to, and then we have to
  ' actually do the database change itself.  We do this by
  ' passing along the variable "ChangePIN".
  '---------------------------------------------------------    
  
  Action = Request.QueryString("ChangePIN")
    Select Case Action
	  Case "Verify"
		  Dim conntemp
		  
		  call OpenDatabase 
		  
		  '------------------------------------------------------
		  ' Compare the two PINs entered if "verify mode" is set.
		  '------------------------------------------------------

		  if request("PIN1") = request("PIN2") then
		    '----------------------------------------
		    ' Disallow the * key as a valid PIN digit
			'----------------------------------------
		  
			if instr(request("PIN1"), "*") = 0 then
			  '-----------------------------------
			  ' Do the actual database save/change
			  '-----------------------------------
			  
		      mySQL="update users set PIN='" & request("PIN1") & "' where phone_number='" & request("session.calledid") & "'"
		      set rstemp=conntemp.execute(mySQL)
		      response.write "<goto value=""$rootdir;/fm2_admin_change_PIN.asp?ChangePIN=OK"" submit=""*"" method=""get""/>"
		      set rstemp=nothing  
		    else
			  '----------------------------------------------------------
			  ' Give the invalid PIN prompt and go back to the Admin Menu
			  '----------------------------------------------------------
			  
			  response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/invalidpin.wav"" /> "
		      response.write "<goto value=""$rootdir;/fm2_admin_menu.xml"" submit=""*"" method=""get"" /> "
			end if		
		  else
		    '------------------------------------------------------------------
		    ' Call this same file, but pass in the "Failed" value for ChangePIN
			'------------------------------------------------------------------
		    
		    response.write "<goto value=""$rootdir;/fm2_admin_change_PIN.asp?ChangePIN=Failed"" submit=""*"" method=""get""/>"	    
		  end if

		  Call CloseDatabase		  
	  
	  '----------------------------------------------------------------------------------------
	  
	  Case "Failed"
	    '----------------------------------------------------------
	    ' Give the PIN failed prompt and go back to the Admin Menu
	    '----------------------------------------------------------	    
	  
  		response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/PINChangeFailed.wav"" cleardigits=""TRUE"" />"
  		response.write "<goto value=""$rootdir;/fm2_admin_menu.xml"" submit=""*"" method=""get"" />"
		
	  '---- -----------------------------------------------------------------------------------
	  
	  Case "OK"
	    '-----------------------------------------------------------------------
 		' Give the PIN changed successfully prompt and go back to the Admin Menu
		'-----------------------------------------------------------------------	  
  		
		response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/PINchanged.wav"" cleardigits=""false"" />"
  		response.write "<goto value=""$rootdir;/fm2_admin_menu.xml"" submit=""*"" method=""get"" />" 
		
	  '-----------------------------------------------------------------------------------------
	  
	  Case "ReadBack"
	    '---------------------------------------------------------------
	    ' PIN Readback is when the caller/user wants the PIN read back
		' to them each time they are asked for the PIN.  This gives them
		' a chance to re-enter it each time if they made a mistake.
		'---------------------------------------------------------------
%>
	    <block label="changePINreadback" repeat="3">
		  <!-- ======================================================= -->
		  <!-- The next 5 variables are for the generic database entry -->
		  <!-- file (fm2_db.asp) that we use in follow me/find me.     -->
		  <!-- ======================================================= -->
		  
	      <assign var="table"    value="users"/>          
	      <assign var="field"    value="PIN_readback"/>
	      <assign var="keyField" value="phone_number"/>
	      <assign var="KeyValue" value="'$session.calledid;'"/>
 	      <assign var="toURL"    value="fm2_admin_menu.xml"/>

	      <playAudio format="audio/wav" 
		             value="$audiorootdir;/changePINReadback.wav" 
		  		     termdigits="12*" 
		             cleardigits="TRUE"/>      	
					 
		  <!-- ================================== -->
		  <!-- Yes, the caller wants PIN readback -->
		  <!-- ================================== -->			 
					 
	      <ontermdigit value="1"> 
	        <playaudio format="audio/wav" value="$audiorootdir;/changePINReadbackYes.wav"/>
	        <assign var="newValue" value="TRUE"/>
	        <goto value="$rootdir;/fm2_db.asp" submit="*" method="get" />
	      </ontermdigit> 
		  
		  <!-- ========================================= -->
		  <!-- No, the caller does not want PIN readback -->
		  <!-- ========================================= -->
		  
	      <ontermdigit value="2"> 
	        <playaudio format="audio/wav" value="$audiorootdir;/changePINReadbackNo.wav"/>
	        <assign var="newValue" value="FALSE"/>
	        <goto value="$rootdir;/fm2_db.asp" submit="*" method="get" />
	      </ontermdigit> 

		  <!-- ====================== -->		  
		  <!-- Back to the Admin Menu -->
		  <!-- ====================== -->		  

	      <ontermdigit value="*"> 
	        <goto value="$rootdir;/fm2_admin_menu.xml" submit="*" method="get" /> 
	      </ontermdigit> 
	    </block>
		
		<simline value="Out of block, returning to admin menu"/>
	    <goto value="$rootdir;/fm2_admin_menu.xml" submit="*" method="get" /> 
		
<%
      '----------------------------------------------------------------------------------------
	  
	  Case "Mode"
	    '-------------------------------------------------------------
	    ' This section is actually for changing the calling mode
		' of Follow Me/Find Me, not the PIN.  Pressing 1 equates
		' to Sequential mode (one number called at a time), while 2
		' equates to Parallel mode (all numbers call at the same time)
		'-------------------------------------------------------------
%>
		 <!-- ======================================================= -->
		 <!-- The next 5 variables are for the generic database entry -->
		 <!-- file (fm2_db.asp) that we use in follow me/find me.     -->
		 <!-- ======================================================= -->
		  
		<assign var="table"    value="users"/>          
		<assign var="field"    value="mode"/>
		<assign var="keyField" value="phone_number"/>
		<assign var="KeyValue" value="'$session.calledid;'"/>
		<assign var="toURL"    value="fm2_admin_menu.xml"/>
		
		<cleardigits/>
		
		<block label="changeMode" repeat="3" cleardigits="FALSE">
		  <playAudio format="audio/wav" 
		             value="$audiorootdir;/changeMode.wav" 
					 termdigits="12*"/>
		      	
		  <ontermdigit value="1"> 
		    <playaudio format="audio/wav" value="$audiorootdir;/changeModeSequential.wav"/>
		    <assign var="newValue" value="1"/>
		    <goto value="$rootdir;/fm2_db.asp" submit="*" method="get" />
		  </ontermdigit> 
		  
		  <ontermdigit value="2"> 
		    <playaudio format="audio/wav" value="$audiorootdir;/changeModeParallel.wav"/>
		    <assign var="newValue" value="2"/>
		    <goto value="$rootdir;/fm2_db.asp" submit="*" method="get" />
		  </ontermdigit> 
		  
		  <!-- ====================== -->		  
		  <!-- Back to the Admin Menu -->
		  <!-- ====================== -->	
		  		  
		  <ontermdigit value="*"> 
		    <goto value="$rootdir;/fm2_admin_menu.xml" submit="*" method="get" /> 
		  </ontermdigit> 
		  <onerror/>
		</block>

<%
      '---- -----------------------------------------------------------------------------------
	  
	  Case "Verification"
	    '-------------------------------------------------------------------
	    ' PIN Verification means that when a call is placed and successfully
		' answered, the person answering will have to enter the PIN code
		' of the user.  It is a more secure way to ensure that someone other
		' than the person who is being sought does not answer and cancel the
		' other Follow Me/Find Me calls (for example, we wouldn't want the
		' family dog answering back accident.
		'-------------------------------------------------------------------
%>
        <cleardigits/>
		<block label="changePINVerification" repeat="3">
		  <!-- ======================================================= -->
		  <!-- The next 5 variables are for the generic database entry -->
		  <!-- file (fm2_db.asp) that we use in follow me/find me.     -->
		  <!-- ======================================================= -->		
		  
		  <assign var="table"    value="users"/>          
		  <assign var="field"    value="PIN_verification"/>
		  <assign var="keyField" value="phone_number"/>
		  <assign var="KeyValue" value="'$session.calledid;'"/>
		  <assign var="toURL"    value="fm2_admin_menu.xml"/>
		  
		  <playaudio format="audio/wav" 
		  			 value="$audiorootdir;/changePINVerification.wav" 
					 termdigits="12*"/>
					 
		  <!-- ====================================== -->
		  <!-- Yes, the caller wants PIN verification -->
		  <!-- ====================================== -->						 
					  
		  <ontermdigit value="1"> 
		    <playaudio format="audio/wav" value="$audiorootdir;/changePINVerificationYes.wav"/>
		    <assign var="newValue" value="TRUE"/>
		    <goto value="$rootdir;/fm2_db.asp" submit="*" method="get" />
		  </ontermdigit> 
		  
		  <!-- ============================================= -->
		  <!-- No, the caller does not want PIN verification -->
		  <!-- ============================================= -->		  
		  
		  <ontermdigit value="2"> 
		    <playaudio format="audio/wav" value="$audiorootdir;/changePINVerificationNo.wav"/>
		    <assign var="newValue" value="FALSE"/>
		    <goto value="$rootdir;/fm2_db.asp" submit="*" method="get" />
		  </ontermdigit> 
		   
		  <!-- ====================== -->		  
		  <!-- Back to the Admin Menu -->
		  <!-- ====================== -->			   
		  
		  <ontermdigit value="*"> 
		    <goto value="$rootdir;/fm2_admin_menu.xml" submit="*" method="get" /> 
		  </ontermdigit> 
		</block>
		
		<simline value="Out of block, returning to Admin Menu"/>
	    <goto value="$rootdir;/fm2_admin_menu.xml" submit="*" method="get" /> 
		
<%  
	  '---- ------------------------------------------------------------------------------------
	  
	  Case Else 
	    '---------------------------------------------------------
	    ' The default option in this file is for the user to enter
		' a new PIN code for themselves (i.e,. change PIN from the
		' admin menu.
		'---------------------------------------------------------
%>
	    <block label="foo">
	      <inputDigits	repeat="3" 
	      			var="PIN1"
	      			format="audio/wav"
	      			maxDigits= "6"
	      			value="$audiorootdir;/enterNewPIN.wav"
	      			termdigits="#" 
	          		maxtime="30s"
	          		maxsilence="45s" >
					
			<!-- ===================================== -->
			<!-- Enter the PIN a second time to verify -->
			<!-- ===================================== -->
					
	        <ontermdigit value="#">
              <% Call VerifyTheNewPin %>
	        </ontermdigit> 
			
			<onmaxdigits>
			  <% Call VerifyTheNewPin %>
			</onmaxdigits>
	      </inputDigits>
	      
	      <onmaxtime>
	        <goto value="$rootdir;/fm2_admin_change_PIN.asp?ChangePIN=Verify" submit="*" method="get"/>
	      </onmaxtime>
		  
	      <onmaxsilence>
	        <goto value="$rootdir;/fm2_admin_change_PIN.asp?ChangePIN=Verify" submit="*" method="get"/>
	      </onmaxsilence>
	    </block>
<%  
	End Select
  
  call WriteFooters

%>

<% Sub VerifyTheNewPin %>
	          <inputDigits	repeat="3"
	      			var="PIN2"
	      			format="audio/wav"
	      			maxDigits="6"
	      			value="$audiorootdir;/reenterNewPIN.wav"
	      			termdigits="#"
	      			cleardigits="TRUE"
	      			includeTermDigits="FALSE"
	            	maxtime="30s"
	            	maxsilence="5s" >
					
	            <ontermdigit value="#">
	              <goto value="$rootdir;/fm2_admin_change_PIN.asp?ChangePIN=Verify" submit="*" method="get"/>
	            </ontermdigit>
				
				<onmaxdigits>
	              <goto value="$rootdir;/fm2_admin_change_PIN.asp?ChangePIN=Verify" submit="*" method="get"/>
				</onmaxdigits>
	          </inputDigits>
<% End Sub %>