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
  Call OpenDatabase
  mySQL="select * from users where phone_number ='" & request("session.calledid") & "'"
  
  set rstemp=conntemp.execute(mySQL)
  if rstemp.eof then
    readback     = FALSE
	verification = FALSE
  else
    readback     = rstemp("PIN_readback")
	verification = rstemp("PIN_verification")
  end if
  
  Call WriteHeaders
  
  if request("PINVerified") = "YES" then
    call OutboundDecision
  elseif request("PINVerified") = "NO" then
    call PINVerification
  else 
    Call OutboundSetup
	Call OutboundClosure
  end if
  
  rstemp.close
  set rstemp=nothing
    
  Call CloseDatabase  
  Call WriteFooters  
%>  

<% Sub OutboundSetup %>
  <block>
    <call value="$numToDial;" maxtime="45s"/>
    <onanswer>
      <block label="loop" repeat="3" cleardigits="false"> 
        <playaudio format="audio/wav" 
		           value="$audiorootdir;/YouHaveCall.wav" 
				   termdigits="12"/> 
		<playnumber format="digits"
				    value="$session.callerid;"
					termdigits="12"/>
<%
        if verification then 
		  call PINVerification
		else 
		  call OutboundDecision
		end if
		
  End Sub
%>				

<%  Sub OutboundDecision %>
        <playaudio format="audio/wav" 
		           value="$audiorootdir;/CallAcceptanceMenu.wav" 
				   termdigits="12"/>
        
		<ontermdigit value="1"> 
		  <block>
		    <sendEvent session="$parentSession;" value="conferenceMe"/> 
		    <wait value="unlimited"/>
			
			<onexternalevent value="Ready">
			  <sendEvent session="$genesisSession;" value="conferenceMe"/>
			  <wait value="unlimited"/>
			</onexternalevent>
		  </block>
		</ontermdigit>
        <ontermdigit value="2"> 
		  <sendEvent session="$parentSession;" value="sendtovm"/> 
		  <hangup/> 
		</ontermdigit>
<% End Sub  %>
<%
 

 

%>

<% Sub OutboundClosure %>
      </block>
	</onanswer>

	<oncallfailure/>
	
    <onmaxtime/>
	
	<onexternalevent value="Kill">
	  <simline value="About to use TTS to inform the listener that another party has accepted the call"/>
	  <text>Another party has accepted the call on a different phone.  Goodbye.</text>
	  
	  <simline value="About to hangup -- This can cause a 'Line Not Active' error if this line did not have an answer event"/>
	  <hangup/>
	</onexternalevent>
	
  </block>
  
<% End Sub %>  

<%
Sub PINVerification
  if request("admin_retries") > 2 then
    response.write "  <block label=""PINFailed"" cleardigits=""true""> " + _
                   "    <playaudio format=""audio/wav"" value=""$audiorootdir;/PINFailed.wav""/>" + _
				   "    <sendevent session=""$parentSession;"" value=""DummyEvent""/>" + _
                   "    <hangup/>" + _
                   "  </block>"
  else
    response.write "  <block label=""verifyPIN"" clearDigits=""TRUE"">" 
    if request("admin_retries") < 1 then
      response.write "    <assign var=""admin_retries"" value=""0""/> "
    end if
    response.write "    <!-- play PIN prompt -->" + _
                   "    <inputDigits repeat=""3"" var=""PIN"" format=""audio/wav"" maxDigits = ""6"" "  + _
                   "               value=""$audiorootdir;/enterPIN.wav"" termdigits=""#"" cleardigits=""TRUE"" " + _
                   "               includeTermDigits=""FALSE"" maxtime=""30s"" maxsilence=""5s"" > " + _
                   "      <ontermdigit value=""#""> "

    if readback then
      response.write "    <block label=""PINreadback"" repeat=""3"" cleardigits=""true""> " + _
                     "      <playaudio format=""audio/wav"" value=""$audiorootdir;/youEntered.wav"" termDigits=""12""  />" + _
                     "      <playNumber format=""digits"" value =""$PIN;"" termDigits=""12""  />" + _   
                     "      <playaudio format=""audio/wav"" value=""$audiorootdir;/PINReadbackMainMenu.wav"" termDigits=""12""  />" + _
                     "        <ontermdigit value=""1""> " +_
                     "          <goto value=""$rootdir;/fm2_admin_verify_PIN.asp?Destination=Parallel"" submit=""*"" method=""get"" /> " + _
                     "        </ontermdigit> " + _
                     "        <ontermdigit value=""2""> " + _
			         "          <goto value=""#verifyPIN"" submit=""*"" method=""get"" />" +_
			         "        </ontermdigit> " + _
                     "    </block>"
    else

      response.write "    <goto value=""$rootdir;/fm2_admin_verify_PIN.asp?Destination=Parallel"" submit=""*"" method=""get"" /> " 
    end if
    response.write "      </ontermdigit> <onmaxtime/> <onmaxsilence/>" + _
 				   "      <onmaxdigits> " + _
			       "        <goto value=""$rootdir;/fm2_admin_verify_PIN.asp?Destination=Parallel"" submit=""*"" method=""get"" />" +_
			       "      </onmaxdigits>" + _
                   "    </inputDigits>" + _
                   "  </block>" 
  end if

End Sub
%>