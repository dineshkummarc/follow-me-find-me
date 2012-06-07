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
  ' This file handles enabling or disabling three aspects of
  ' Follow Me/Find Me.  The first is voicemail (on or off), 
  ' the second is a specific number in the Follow Me/Find Me
  ' list (on or off), and third is the entire Follow Me/Find
  ' Me service itself (off would mean it would send callers
  ' directly to voicemail, if that option were turned on).
  '---------------------------------------------------------
  
  Action = Request.QueryString("Enable")
    Select Case Action
	  Case "VM"
	    '-------------------------------------------------------------------
	    ' We set the next five variables for our generic databasing file, 
		' called "fm2_db.asp"  If we end up making a change, the information
		' below is used to generate the SQL statement.
		'-------------------------------------------------------------------
%>
		<assign var="table"    value="users"/>          
		<assign var="field"    value="VM_on_No_answer"/>
		<assign var="keyField" value="phone_number"/>
		<assign var="KeyValue" value="'$session.calledid;'"/>
		<assign var="toURL"    value="fm2_admin_global_properties.xml"/>
		
		<cleardigits/>
		<block label="enableVM" repeat="3">
		  <playAudio format="audio/wav" value="$audiorootdir;/enableVM.wav" termdigits="12*"/>
			  
		   <!-- ========================================= -->
		   <!-- Pressing 1 enables voicemail on no answer -->
		   <!-- ========================================= -->	  
		    	
		   <ontermdigit value="1"> 
		     <playaudio format="audio/wav" value="$audiorootdir;/enableVMYes.wav"/>
		     <assign var="newValue" value="TRUE"/>
		     <goto value="$rootdir;/fm2_db.asp" submit="*" method="get" />
		   </ontermdigit> 
		   
		   <!-- ========================================== -->
		   <!-- Pressing 2 disables voicemail on no answer -->
		   <!-- ========================================== -->
		   
		   <ontermdigit value="2"> 
		     <playaudio format="audio/wav" value="$audiorootdir;/EnableVMNo.wav"/>
		     <assign var="newValue" value="FALSE"/>
		     <goto value="$rootdir;/fm2_db.asp" submit="*" method="get" />
		   </ontermdigit> 

		   <!-- ================================================================ -->
		   <!-- Pressing * returns the user/caller to the global properties menu -->
		   <!-- ================================================================ -->
		   
		   <ontermdigit value="*"> 
		     <goto value="$rootdir;/fm2_admin_global_properties.xml" submit="*" method="get" /> 
		   </ontermdigit> 
		 </block> <!-- enableVM -->
		 
		<goto value="$rootdir;/fm2_admin_global_properties.xml" submit="*" method="get" />		 
<%  
	  '---- ------------------------------------------------------------------	  
	  
	  Case "Number"
	    '-------------------------------------------------------------------
	    ' We set the next five variables for our generic databasing file, 
		' called "fm2_db.asp"  If we end up making a change, the information
		' below is used to generate the SQL statement.
		'-------------------------------------------------------------------
%>
		<assign var="table"     value="fm2_numbers"/>          
		<assign var="field"     value="enabled"/>
		<assign var="keyField"  value="ID"/>
		<assign var="KeyValue"  value="$current_number_id;"/>       
		<assign var="toURL"     value="fm2_admin_number_config.asp"/>
		
		<cleardigits/>
		<block label="enableNumber" repeat="3">
		  <playAudio format="audio/wav" value="$audiorootdir;/enableNumber.wav" termdigits="12*"/>
		    	
		   <!-- ===================================== -->
		   <!-- Pressing 1 enables the current number -->
		   <!-- ===================================== -->	  

		  <ontermdigit value="1"> 
		    <playaudio format="audio/wav" value="$audiorootdir;/enableNumberYes.wav"/>
		    <assign var="newValue" value="TRUE"/>
		    <goto value="$rootdir;/fm2_db.asp" submit="*" method="get" />
		  </ontermdigit> 

		  <!-- ====================================== -->
		  <!-- Pressing 2 disables the current number -->
		  <!-- ====================================== -->

		  <ontermdigit value="2"> 
		    <playaudio format="audio/wav" value="$audiorootdir;/enableNumberNo.wav"/>
		    <assign var="newValue" value="FALSE"/>
		    <goto value="$rootdir;/fm2_db.asp" submit="*" method="get" />
		  </ontermdigit> 

		  <!-- ================================================================ -->
		  <!-- Pressing * returns the user/caller to the global properties menu -->
		  <!-- ================================================================ -->

		  <ontermdigit value="*"> 
		    <goto value="$audiorootdir;/fm2_admin_global_properties.xml" submit="*" method="get" /> 
		  </ontermdigit> 
		</block> <!-- enableNumber -->
		
		<goto value="$rootdir;/fm2_admin_number_config.asp" submit="*" method="get" />		
<%	    
	  '---- ------------------------------------------------------------------
	  
	  Case "FM2"
	    '-------------------------------------------------------------------
	    ' We set the next five variables for our generic databasing file, 
		' called "fm2_db.asp"  If we end up making a change, the information
		' below is used to generate the SQL statement.
		'-------------------------------------------------------------------
%>	  
		<assign var="table"    value="users"/>          
		<assign var="field"    value="FM2Enabled"/>
		<assign var="keyField" value="phone_number"/>
		<assign var="KeyValue" value="'$session.calledid;'"/>
		<assign var="toURL"    value="fm2_admin_global_properties.xml"/>
		
		<cleardigits/>
		<block label="enableFM2" repeat="3">
		  <playAudio format="audio/wav" value="$audiorootdir;/enableFM2.wav" termdigits="12*"/>   

	      <!-- ==================================== -->
	      <!-- Pressing 1 enables follow me/find me -->
	      <!-- ==================================== -->	  
					    	
		  <ontermdigit value="1"> 
		    <playaudio format="audio/wav" value="$audiorootdir;/enableFM2Yes.wav"/>
		    <assign var="newValue" value="TRUE"/>
		    <goto value="$rootdir;/fm2_db.asp" submit="*" method="get" />
		  </ontermdigit> 
		  
		  <!-- ===================================== -->
		  <!-- Pressing 2 disables follow me/find me -->
		  <!-- ===================================== -->
	  		  
		  <ontermdigit value="2"> 
		    <playaudio format="audio/wav" value="$audiorootdir;/EnableFM2No.wav"/>
		    <assign var="newValue" value="FALSE"/>
		    <goto value="$rootdir;/fm2_db.asp" submit="*" method="get" />
		  </ontermdigit> 
		  
		  <!-- ================================================================ -->
		  <!-- Pressing * returns the user/caller to the global properties menu -->
		  <!-- ================================================================ -->
		  
		  <ontermdigit value="*"> 
		    <goto value="$rootdir;/fm2_admin_global_properties.xml" submit="*" method="get" /> 
		  </ontermdigit> 
		</block> <!-- enableFM2 -->	
		
		<goto value="$rootdir;/fm2_admin_global_properties.xml" submit="*" method="get" />
<%   
	End Select
		     
  call WriteFooters
%>