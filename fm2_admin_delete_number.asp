<%@ LANGUAGE = VBScript %>

<!-- #include file="subs.asp" -->

<!-- may need to reindex numbers on deletion -->

<%
  ' ---------------------------------------------------
  ' copyright 2000 by voxeo corporation. (see LGPL.txt)
  '
  ' v1.0 Coded in ASP
  ' v1.0 Coded by Ryan Campbell and Stephen J. Lewis
  ' ---------------------------------------------------
  
  call WriteHeaders
  
  '-------------------------------------------------------------
  ' Like many of the FM2 files, there is a first and a second
  ' pass through.  Here, the first pass will ask the user/caller
  ' for verification of the number delete, the second will 
  ' do the actual deletion.
  '-------------------------------------------------------------
  
  if Request.QueryString("DeleteNumber") = "YES" then
    Dim conntemp
	call OpenDatabase 
  
    call DeleteVMNumber
	
    Call CloseDatabase  
  else
%>
	<block label="deleteNumber" repeat="3">
	<playAudio format="audio/wav" 
	           value="$audiorootdir;/DeleteNumber.wav" 
			   termdigits="1*" 
			   cleardigits="TRUE"/>
			   
	  <!-- ========================================== -->
	  <!-- If they press 1 to delete the number, then -->
	  <!-- We ask they again to verify that deletion. -->
	  <!-- ========================================== -->		   
			   
			   
	  <ontermdigit value="1">
	    <block label="verifyDelete" repeat="3">
	      <playAudio format="audio/wav" 
		             value="$audiorootdir;/confirmDelete.wav" 
					 termdigits="12" 
		             cleardigits="TRUE"/>
					 
		  <!-- ========================================================= -->
		  <!-- Call this script again when they press 1 to do the delete -->
		  <!-- ========================================================= -->
		  
					 
	      <ontermdigit value="1"> 
	        <goto value="$rootdir;/fm2_admin_delete_number.asp?DeleteNumber=YES" submit="*" method="get" />
	      </ontermdigit>
		  
		  <!-- ============================================== -->
		  <!-- Return to the Admin Number Configuration menu  -->
		  <!-- because the user/caller did not want to delete -->
		  <!-- ============================================== -->
		  
	      <ontermdigit value="2"> 
	        <goto value="$rootdir;/fm2_admin_number_config.asp" submit="*" method="get"/> 
	      </ontermdigit>
	    </block> <!-- verifyDelete -->
	  </ontermdigit> 
	  
	  <!-- ============================================== -->
	  <!-- Return to the Admin Number Configuration menu  -->	  
	  <!-- ============================================== -->
	  
	  <ontermdigit value="*"> 
	    <goto value="$rootdir;/fm2_admin_number_config.asp" submit="*" method="get"/> 
	  </ontermdigit>
	  
	  <!-- ================================================ -->
	  <!-- Repeat the block on either maxtime or maxsilence -->
	  <!-- ================================================ -->
	  
	  <onmaxtime/>
	  <onmaxsilence/>
	</block> <!-- deleteNumber -->
	
    <!-- ============================================== -->
    <!-- Return to the Admin Number Configuration menu  -->	  
    <!-- ============================================== -->	

    <goto value="$rootdir;/fm2_admin_number_config.asp" submit="*" method="get" />

<%  
  end if
  
  call WriteFooters
  
  '-------------------------------------------------------------------------------------

  Sub DeleteVMNumber
    '----------------------------------------------------------
    ' Here is where we simply delete current number in the list
	'----------------------------------------------------------
    
    mySQL= "delete * from fm2_numbers where id=" & request("current_number_id")

    set rstemp=conntemp.execute(mySQL)
    set rstemp=nothing
	
	response.write "<assign var=""current_number_id"" value=""0""/>"
    
	'----------------------------------------------
	' Return to the Admin Number Configuration menu
	'----------------------------------------------
	
    response.write "<playaudio format=""audio/wav"" value=""$audiorootdir;/numberDeleted.wav"" />" + _
                   "<goto value=""$rootdir;/fm2_admin_number_config.asp"" submit=""*"" method=""get"" />"
  End Sub
%>

