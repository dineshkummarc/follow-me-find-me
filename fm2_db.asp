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
    
  mySQL= "update " & request("table") & " set " & request("field") & "=" & request("newValue") 
  mySQL= mySQL & " where " & request("keyField") & "=" & request("keyValue") 
  set rstemp=conntemp.execute(mySQL)
    
  set rstemp=nothing  
  
  call CloseDatabase
  
  response.write "<?xml version=""1.0"" encoding=""UTF-8""?>" + _
                 "<callxml>" + _
                 "  <simline value=""SQL= "  & mySQL & """/>" + _
                 "  <simline value=""URL= "  & request("toURL") & """/>" + _
  
                 "  <clear var=""table""    />" + _          
                 "  <clear var=""field""    />" + _
                 "  <clear var=""keyField"" />" + _
                 "  <clear var=""KeyValue"" />" + _
                 "  <clear var=""toURL""    />" + _
                 "  <clear var=""newValue"" />" + _

  
                 "  <goto value=""" & request("toURL") & """ submit=""*"" method=""get"" /> " + _
                 "</callxml>"  
%>

