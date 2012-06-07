<%
  ' ---------------------------------------------------
  ' copyright 2000 by voxeo corporation. (see LGPL.txt)
  '
  ' v1.0 Coded in ASP
  ' v1.0 Coded by Ryan Campbell and Stephen J. Lewis
  ' ---------------------------------------------------
  
  Sub WriteHeaders
    response.write "<?xml version=""1.0"" encoding=""UTF-8""?>" + _
    		   "<callxml>"
  End Sub
  
  '-------------------------------------------------------------------

  Sub WriteFooters
    response.write "</callxml>"  
  End Sub

  '-------------------------------------------------------------------

  Sub CloseDatabase
    conntemp.close
    set conntemp=nothing
  End Sub

  '-------------------------------------------------------------------

  Sub OpenDatabase
	Set conntemp = Server.CreateObject("ADODB.Connection")
	conntemp.Open "fm2"
  End Sub

  '-------------------------------------------------------------------
  
  Function GetHTTPUsername
    '-------------------------------------------------------
    ' This function simply allows you to change the Username
    ' for HTTP requests.  Edit the value below as needed.
    '-------------------------------------------------------  
    
	Username = ""
	
	GetHTTPUsername = Username
  End Function
  
  '-------------------------------------------------------------------
 
  Function GetHTTPPassword
    '-------------------------------------------------------
    ' This function simply allows you to change the Password
    ' for HTTP requests.  Edit the value below as needed.
    '------------------------------------------------------- 
	  
    Password = ""
	
	GetHTTPPassword = Password  
  End Function
  
  '-------------------------------------------------------------------

  Function GetFTPUsername
    '-------------------------------------------------------
    ' This function simply allows you to change the Username
    ' for FTP requests.  Edit the value below as needed.
    '------------------------------------------------------- 
	  
    Username = "opensource"
	
	GetFTPUsername = Username 
  End Function
  
  '-------------------------------------------------------------------

  Function GetFTPPassword
    '-------------------------------------------------------
    ' This function simply allows you to change the Password
    ' for FTP requests.  Edit the value below as needed.
    '------------------------------------------------------- 
	  
    Password = "pingpong"
	
	GetFTPPassword = Password  
  End Function
%>