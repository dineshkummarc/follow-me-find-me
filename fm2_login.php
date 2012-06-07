<?PHP

include('database-win32.inc');

$Path = "http://appserverdev.voxeo.com/fm2/";

echo "<html>";

 echo "<body BGColor=#264c73 TEXT=White LINK=White " . 
	       "ALINK=#9999FF vlink=White leftmargin=0 topmargin=0>\n";

//------------------------------------------------------------------------------------

function GetTotalNumbers($UserID) {
  $TempConnection = OpenDatabase("FM2");
  $TempSQL        = "select * from fm2_numbers where User_ID = " . $UserID;
  $TempRecordSet  = ReadDatabase($TempConnection, $TempSQL);
  $TotalNumbers   = 0;
  
  while ($TempRow = FetchRowFromDatabase($TempRecordSet)){
    $TotalNumbers++;
  }  // while loop
  
  return $TotalNumbers;
}  // function GetTotalNumbers

//------------------------------------------------------------------------------------

function CheckLogin($Number, $PIN) {
  $TempConnection = OpenDatabase("FM2");
  $TempSQL        = "select ID from Users where " .
                    "phone_number = '$Number' AND PIN = '$PIN'";
  $TempDatabase   = ReadDatabase($TempConnection, $TempSQL);
  
  //------------------------------------------------------
  // Check and see if the Number/PIN match an entry in our
  // database.  If they do, return the ID of the user, if
  // not then return -1, which means there was no match.
  //------------------------------------------------------
  
  if ($TempRow = FetchRowFromDatabase($TempDatabase)) {
    $Result = GetResultFromRow( "ID", $TempRow, $TempDatabase );
  }  // if statement
  else {
    $Result = -1;
  }  // else statement
  
  CloseDatabase($TempConnection);
  
  return $Result;
}  // CheckLogin function

//------------------------------------------------------------------------------------

function StripNonNumbers($PhoneNumber) {
  $TheNumber = "";

  //--------------------------------------
  // Remove the non-numbers, if they exist
  //--------------------------------------
	
  for ($Loopy = 0; $Loopy <= strlen($PhoneNumber); $Loopy++) {
    if (($PhoneNumber[$Loopy] >= "0") && ($PhoneNumber[$Loopy] <= "9")) {
	  $TheNumber = $TheNumber . $PhoneNumber[$Loopy];
	}  // if statement
  }  // for loop

  return $TheNumber;
}  // function StripNonNumbers

//------------------------------------------------------------------------------------

function UpdateAccount($UserID) {
  global $HTTP_POST_VARS;
  
  //-------------------------------------------
  // Update the user information/settings first
  //-------------------------------------------

  $TempConnection = OpenDatabase("FM2");
  $TempSQL        = "update Users set "; 
					
  if ($HTTP_POST_VARS["FM2Enabled"]) { $TempSQL = $TempSQL . "fm2Enabled = TRUE, ";  }
  else                               { $TempSQL = $TempSQL . "fm2Enabled = FALSE, "; }
  
  if ($HTTP_POST_VARS["VoicemailAnswer"]) { $TempSQL = $TempSQL . "VM_on_No_answer = TRUE, ";  }
  else                                    { $TempSQL = $TempSQL . "VM_on_No_answer = FALSE, "; }

  if ($HTTP_POST_VARS["PINVerification"]) { $TempSQL = $TempSQL . "PIN_verification = TRUE, ";  }
  else                                    { $TempSQL = $TempSQL . "PIN_verification = FALSE, "; }

  if ($HTTP_POST_VARS["Mode"]) { $TempSQL = $TempSQL . "Mode = 2, "; }
  else                         { $TempSQL = $TempSQL . "Mode = 1, "; }
  
  $TempSQL = $TempSQL . "voicemail_number = '" . $HTTP_POST_VARS["Voicemail"] . "', ";
  
  if ($HTTP_POST_VARS["PINReadback"]) { $TempSQL = $TempSQL . "PIN_readback = TRUE ";  } 
  else                                { $TempSQL = $TempSQL . "PIN_readback = FALSE "; }
  

  $TempSQL = $TempSQL . "where ID = " . $UserID;
			
  $TempDatabase = ReadDatabase($TempConnection, $TempSQL); 
  
  //---------------------------------
  // Now update the phone number list
  //---------------------------------
  
  $TotalNumbers = GetTotalNumbers($UserID);
  
  for ($Loopy = 1; $Loopy <= $TotalNumbers; $Loopy++) {
    $TheNumber = StripNonNumbers($HTTP_POST_VARS["PhoneNumber" . $Loopy]);
		
	if ($TheNumber == "") {
	  $TempSQL = "delete * from fm2_numbers where ID = " . 
	  			 $HTTP_POST_VARS["UniqueID" . $Loopy];
	}  // if statement
	else {
	  $TempSQL = "update fm2_numbers set " . 
	 		   "dial_number = '" . $TheNumber . "', ";
				 
	  if ($HTTP_POST_VARS["PhoneEnabled" . $Loopy]) { $TempSQL = $TempSQL . "enabled = TRUE ";  }
	  else                                          { $TempSQL = $TempSQL . "enabled = FALSE "; }
	  
	  $TempSQL = $TempSQL . "where ID = " . $HTTP_POST_VARS["UniqueID" . $Loopy];
	}  // else statement

	$TempDatabase = ReadDatabase($TempConnection, $TempSQL);	
  }  // for loop
  
  //--------------------------------------------------
  // And now to add a new number, if that is necessary
  //--------------------------------------------------
  
  if ($HTTP_POST_VARS["NewNumber"] != "") {
    //--------------------------------------------------------
    // First let's get the highest position in the user's
	// current phone list, and make this one higher than that.
	//--------------------------------------------------------
	
	$TempDatabase = ReadDatabase($TempConnection, "select num_Order from fm2_numbers " . 
				    "where User_ID = $UserID order by num_Order desc");
					
	if ($TempRow = FetchRowFromDatabase($TempDatabase)) {
	  $Position = (GetResultFromRow("num_Order", $TempRow, $TempDatabase) + 1);
	}  // if statement
	else {
	  $Position = 1;
	}  // else statement
	
	$TheNumber = StripNonNumbers($HTTP_POST_VARS["NewNumber"]);
	
	//---------------------------
	// Check for duplicate numbers
    //----------------------------
	
	$DuplicateNumber = "NO";
	  
	for ($Loopy1 = 1; $Loopy1 <= $TotalNumbers; $Loopy1++) {
	  if ($TheNumber == $HTTP_POST_VARS["PhoneNumber" . $Loopy1]) {
	    $DuplicateNumber = "YES";	    
	  }  // if statement
	}  // for loop
	
	if ($TheNumber != "") {
	  if ($DuplicateNumber == "NO") {
	    $TempSQL = "insert into fm2_numbers (num_Order, User_ID, dial_number, enabled) values " . 
			       "( $Position, $UserID, '" . $TheNumber . "', TRUE)";
			   
	    $TempDatabase = ReadDatabase($TempConnection, $TempSQL);
	  }  // if statement
	}  // if statement
  }  // if statement
  
  CloseDatabase($TempConnection);
}  // UpdateAccount function

//------------------------------------------------------------------------------------

function DisplayUserScreen($UserID) {
  $TempConnection = OpenDatabase("FM2");
  $TempDatabase   = ReadDatabase($TempConnection, 
  					"select * from Users where ID = $UserID");
			
  echo "<table width=600 align=center cellpadding=0 border=0>\n<tr><td>\n";  
  echo "<b><font color=#9999FF size=5 face=Arial>account information</font></b><p>\n";
  echo "</td></tr></table>\n";
  echo "<table width=400 align=left cellpadding=5 border=0>\n<tr><td align=right>\n";  
					
  if ($TempRow = FetchRowFromDatabase($TempDatabase)) {
    $FirstName 		 = GetResultFromRow("First",			$TempRow, $TempDatabase );
	$LastName  		 = GetResultFromRow("Last", 			$TempRow, $TempDatabase );
    $PhoneNumber 	 = GetResultFromRow("phone_number",		$TempRow, $TempDatabase );
    $Voicemail 		 = GetResultFromRow("voicemail_number", $TempRow, $TempDatabase );
    $PIN 			 = GetResultFromRow("PIN",				$TempRow, $TempDatabase );
    $Address1		 = GetResultFromRow("address1",			$TempRow, $TempDatabase );
    $Address2		 = GetResultFromRow("address2",			$TempRow, $TempDatabase );
    $City			 = GetResultFromRow("City",				$TempRow, $TempDatabase );
    $State	 		 = GetResultFromRow("State",			$TempRow, $TempDatabase );
    $ZipCode         = GetResultFromRow("Zip",				$TempRow, $TempDatabase );
    $Enabled         = GetResultFromRow("fm2Enabled",		$TempRow, $TempDatabase );
    $VoicemailAnswer = GetResultFromRow("VM_on_No_answer",	$TempRow, $TempDatabase );										
    $PINVerification = GetResultFromRow("PIN_verification",	$TempRow, $TempDatabase );
    $PINReadback     = GetResultFromRow("PIN_readback",		$TempRow, $TempDatabase );
    $Mode            = GetResultFromRow("mode",				$TempRow, $TempDatabase );		
	
	echo "<form action=\"" . $Path . "fm2_login.php\" method=post name=\"User\">\n";
	
    $Text = "follow me/find me enabled <input type=checkbox name=FM2Enabled";
    if ($Enabled) { $Text = $Text . " checked"; }
    $Text = $Text . ">\n<br>";
	
    $Text = $Text . "use PIN verification over the phone <input type=checkbox name=PINVerification";
    if ($PINVerification) { $Text = $Text . " checked"; }
    $Text = $Text . ">\n<br>";	
	
    $Text = $Text . "go to voicemail on no answer <input type=checkbox name=VoicemailAnswer";
    if ($VoicemailAnswer) { $Text = $Text . " checked"; }
    $Text = $Text . ">\n<br>";	
    
	$Text = $Text . "use parallel mode dialing <input type=checkbox name=Mode";
    if ($Mode == "2") { $Text = $Text . " checked"; }
    $Text = $Text . ">\n<br>";	
	
    $Text = $Text . "user PIN readback over the phone <input type=checkbox name=PINReadback";
    if ($PINReadback) { $Text = $Text . " checked"; }
    $Text = $Text . ">\n<br><hr>\n";	
  
    echo "<font face=Arial size=1>$Text</font>";
	
	//---------------------------------------------
	// Now we need to display all the phone numbers
	// the current user has listed.
	//---------------------------------------------
	
	echo "<font color = #9999FF size=3><b>here are your current " . 
		 "follow me/find me numbers:</font></b><p>\n";
	
	$TempDatabase = ReadDatabase($TempConnection, 
					"select * from fm2_numbers where User_ID = $UserID order by num_Order");
	
	$PhoneEnabled = array();
	$Position     = array();
	$ZPhoneNumber = array();
	$UniqueIDs    = array();
	
	$Loopy = 0;
	
	echo "<font face=Arial size=1>";
	
	while ($TempRow = FetchRowFromDatabase($TempDatabase)) {
	  $Loopy++;
	  
	  $PhoneEnabled[$Loopy] = GetResultFromRow("enabled",     $TempRow, $TempDatabase);
	  $Position[$Loopy]     = GetResultFromRow("num_Order",   $TempRow, $TempDatabase);
	  $ZPhoneNumber[$Loopy] = GetResultFromRow("dial_number", $TempRow, $TempDatabase);
	  $UniqueIDS[$Loopy]    = GetResultFromRow("ID",          $TempRow, $TempDatabase);
	  
	  echo "position " . $Position[$Loopy] . " ";
	  
	  echo "<input type=text name=\"PhoneNumber" . $Loopy . "\" " .
	  	   "size=12 maxlength=12 value=\"". $ZPhoneNumber[$Loopy] . "\">\n ";
		   
	  $Text = "<input type=checkbox name=\"PhoneEnabled" . $Loopy . "\"";
	  if ($PhoneEnabled[$Loopy]) { $Text = $Text . " checked"; }
	  $Text = $Text . ">\n<br>";
	  
	  echo $Text;
	  
	  echo "<input type=hidden name=\"UniqueID" . $Loopy . 
	  	   "\" value=\"" . $UniqueIDS[$Loopy] . "\">\n";	  
	}  // while loop
	
	//---------------------------------------------------------
	// Check to see if there are any phone numbers in the list.
	//---------------------------------------------------------
	
	if ($Loopy == 0) {
	  echo "<font color=red>there are currently no numbers in your list.</font><br>\n";
	}  // if statement
	
	echo "<br>new number <input type=text name=\"NewNumber\" size=12 maxlength=12>\n<br>";
	
	echo "<input type=hidden name=\"TotalNumbers\" value=\"" . $Loopy . "\">\n";		
	echo "<input type=hidden name=\"UserID\" value=\"" . $UserID . "\">\n";
			
	if ($Loopy != 0) {
	  echo "<br>\n<div align=left>the checkbox next to your follow me/find me numbers enables";
	  echo " and disables them.  this allows you to easily, but temporarily";
	  echo " remove a number from your list. &nbsp;";
 	  echo "to delete a number entirely, simply leave the field " .
		   "blank and update your account.</div>\n<p>";
	}  // if statement
	else {
	  echo "<p>";
	}  // else statement
	
	echo "voicemail number <input type=text name=\"Voicemail\" " . 
	                       "size=20 maxlength=30 value=\"" . $Voicemail . "\">\n<br>";
						   
	echo "Note: Your voicemail number can be an email address.<p>";	
	
	echo "<input type=submit name=\"Submit\" value=\"Update Account\">\n";	
					
	echo "<hr>\n";
	echo $FirstName . " " . $LastName . "<br>\n";
	
	if ($Address1 != "") { echo $Address1 . "<br>\n"; }
	if ($Address2 != "") { echo $Address2 . "<br>\n"; }
	
	if (($City != "") && ($State != "") && ($ZipCode != "")) {
   	  echo $City . " " . $State . ", " . $ZipCode . "<br>";
	}  // if statement
	
	if ($Voicemail == "") { $Voicemail = "Unassigned"; }
		
	echo "</form>\n";
	echo "</font>";
	
  }  // if statement
  else {
    echo "<font color=red>There has been an error displaying your account.<br>";
	echo "Please contact your administrator.";
  }  // else statement
  
  echo "</td></tr></table>\n";
  					
  CloseDatabase($TempConnection);
}  // DisplayUserScreen function

//------------------------------------------------------------------------------------

function CreateNewUser() {
  global $HTTP_POST_VARS;
  
  if ($HTTP_POST_VARS["Voicemail"] != "") { $VoicemailOption = "TRUE";   }
  else 								      { $VoicemailOption = "FALSE";  }
  
  echo "<font size=1>";
  echo "Opening database...<br>";
  
  $TempConnection = OpenDatabase("FM2");

  echo "Adding your user account...<br>";  
  
  $TempSQL = "select * from Users where phone_number = '" . $HTTP_POST_VARS["PhoneNumber"] . "'";
  
  $TempDatabase = ReadDatabase($TempConnection, $TempSQL);
  
  while ($TempRow = FetchRowFromDatabase($TempDatabase)) {
    $NumberAlreadyExists = "YES";
  }  // while loop
  
  if ($NumberAlreadyExists != "YES") {
    $TempSQL = "insert into Users (First, Last, phone_number, voicemail_number, PIN, address1, " . 
      		   "address2, City, State, Zip, fm2Enabled, VM_on_No_answer, " .
			   "PIN_verification, PIN_readback, mode) values (" . 
			   "'" . $HTTP_POST_VARS["FirstName"]   . "', " .
			   "'" . $HTTP_POST_VARS["LastName"]    . "', " .
			   "'" . $HTTP_POST_VARS["PhoneNumber"] . "', " .
			   "'" . $HTTP_POST_VARS["Voicemail"]   . "', " .
			   "'" . $HTTP_POST_VARS["Pin1"]        . "', " .		
		       "'" . $HTTP_POST_VARS["Address1"]    . "', " .
			   "'" . $HTTP_POST_VARS["Address2"]    . "', " .
			   "'" . $HTTP_POST_VARS["City"]        . "', " .
			   "'" . $HTTP_POST_VARS["State"]       . "', " .
			   "'" . $HTTP_POST_VARS["Zip"]         . "', " .
			   "TRUE, " .                   // <---- Defaults to FM2 being enabled
			   $VoicemailOption . ", " .    
			   "TRUE, " .                   // <---- Defaults to PIN Verification
			   "FALSE, " .                  // <---- Defaults to NO Pin Readback
			   "2)";                        // <---- Defaults to parallel mode
			   
    $TempDatabase = ReadDatabase($TempConnection, $TempSQL);
  
    echo "<p>User account complete.  Your Follow Me/Find Me number is " . 
         "<font color=#9999FF><b>" . $HTTP_POST_VARS["PhoneNumber"] . "</b></font>.<br>";
    echo "You may use it in combination with your PIN to login via the web or the phone.<p>";
    echo "To further configure your Follow Me/Find Me account, " . 
         "<A HREF=\"fm2_login.php\">please login</A><br>";
  }  // if statement
  else {
    echo "<p><font color=red><b>That account already exists in the database.  To create a new account, please " . 
         "<A HREF=\"fm2_login.php\">return to the main page</A> and select signup.<br>";
  }  // else statement
  
  CloseDatabase($TempConnection);																																					
}  // CreateNewUser function

//------------------------------------------------------------------------------------

function DisplaySignupForm() {
  global $HTTP_POST_VARS;
  
  echo "<table width=500 align=center cellpadding=0><tr><td>";  
  echo "<b><font color=#9999FF size=5 face=Arial>account setup</font></b><p>";
  
  echo "<font size=1 face=arial>your follow me/find me number should already be " . 
       "provisioned from voxeo's <a href=\"http://community.voxeo.com\" target=\"_blank\">" . 
	   "community site</a>. if it has not been provisioned, then while an account in " .
	   "the database will be set up here, you will not be able to call into it.</font><p>";
    
  //------------------------------------------------------------
  // If the user already hit "create account" then we need to 
  // check and see if all the required fields have been entered.
  //------------------------------------------------------------
  
  if ($HTTP_POST_VARS["Submit"] == "Create Account") {
    $Error = "NO";  
	
	if (($HTTP_POST_VARS["PhoneNumber"] == "") ||
	    ($HTTP_POST_VARS["FirstName"]   == "") ||
	    ($HTTP_POST_VARS["LastName"]    == "") ||
		($HTTP_POST_VARS["Pin1"]        == "") ||
		($HTTP_POST_VARS["Pin2"]        == "") ||
		($HTTP_POST_VARS["Zip"]         == ""))   {
		
	  echo "<font color=red>You have left one or<br>more required fields blank.</font><p>";
	  $Error = "YES";
	}  // if statement
	
	if ( $HTTP_POST_VARS["Pin1"] != $HTTP_POST_VARS["Pin2"] ) {
	  echo "<font color=red>Your PINs do not match.<br>Please try again.</font><p>";
	  $Error = "YES";
	}  // if statement
	
	//-------------------------------------------------------
	// If there are, in fact, no errors, then we need to save
	// off the new user to our database.
	//-------------------------------------------------------
	
	if ($Error == "NO") {
	  CreateNewUser();
	  exit();
	}  // if statement
  }  // if statement

  echo "<form action=\"" . $Path . "fm2_login.php\" method=post name=\"SignupForm\">";  

  echo "</td></tr><tr><td>";
  
  echo "<font size=2>";
  
  echo "follow me/find me number *<br>";
  echo "<input type=text name=\"PhoneNumber\" value=\"" . $HTTP_POST_VARS["PhoneNumber"] . 
  			  "\" size=20 maxlength=10><br><br>";

  echo "firstname *<br>";
  echo "<input type=text name=\"FirstName\" value=\"" . $HTTP_POST_VARS["FirstName"] . 
  			  "\" size=20 maxlength=20><br>";
  echo "lastname *<br>";
  echo "<input type=text name=\"LastName\" value=\"" . $HTTP_POST_VARS["LastName"] . 
  			  "\" size=20 maxlength=20><br><br>";	

  echo "address line 1<br>";
  echo "<input type=text name=\"Address1\" value=\"" . $HTTP_POST_VARS["Address1"] . 
  			  "\" size=20 maxlength=20><br>";
  echo "address line 2<br>";
  echo "<input type=text name=\"Address2\" value=\"" . $HTTP_POST_VARS["Address2"] . 
  			  "\" size=20 maxlength=20><br>";
			  
  echo "city<br>";
  echo "<input type=text name=\"City\" value=\"" . $HTTP_POST_VARS["City"] . 
  			  "\" size=20 maxlength=20><br>";

  echo "</td><td><font size=2>";			  
			  
  echo "state<br>";
  echo "<input type=text name=\"State\" value=\"" . $HTTP_POST_VARS["State"] . 
  			  "\" size=2 maxlength=2><br>";		
  echo "zip *<br>";
  echo "<input type=text name=\"Zip\" value=\"" . $HTTP_POST_VARS["Zip"] . 
  			  "\" size=5 maxlength=5><br><br>";			  

  echo "voicemail number<br>";
  echo "<input type=text name=\"Voicemail\" value=\"" . $HTTP_POST_VARS["Voicemail"] . 
  			  "\" size=20 maxlength=30><br><br>";

  echo "pin *<br>";
  echo "<input type=password name=\"Pin1\" value=\"" . $HTTP_POST_VARS["Pin1"] . 
  			  "\" size=8 maxlength=6><br>";	
  echo "verify pin *<br>";  
  echo "<input type=password name=\"Pin2\" value=\"" . $HTTP_POST_VARS["Pin2"] . 
  			  "\" size=8 maxlength=6>";
			  
  echo "</td></tr><tr><td><br><hr>";
  
  echo "* denotes required field<p>";
  
  echo "<input type=submit name=\"Submit\" value=\"Create Account\">";
  
  echo "</form>";
  echo "</td></tr></table>";
}  // DisplaySignupForm function

//------------------------------------------------------------------------------------

function GreetTheUser($UserID) {
  $TempConnection = OpenDatabase("FM2");
  $TempDatabase   = ReadDatabase($TempConnection, 
  					"select First from Users where ID = $UserID");
  
  $Name = "";
  
  if ($TempRow = FetchRowFromDatabase($TempDatabase)) {
    $Name = GetResultFromRow("First", $TempRow, $TempDatabase);
  }  // if statement
  
  echo "<font size=2>&nbsp;welcome back <font color=#9999FF><b> $Name </b></font><br>\n";
  echo "feel free to edit your account<p></font>\n";	
  
  CloseDatabase($TempConnection);
}  // GreetTheUser function

//------------------------------------------------------------------------------------


function DisplayMainScreen() {
  global $Path;
  global $HTTP_POST_VARS;
  
  $DisplayLoginBox = "YES";
  
  if ($HTTP_POST_VARS["Submit"] == "Login") {
    //-------------------------------------------------------------
    // Don't even bother checking if either of the variables passed 
	// in are empty.
	//-------------------------------------------------------------
  
	if (($HTTP_POST_VARS["FM2_Number"] != "") && ($HTTP_POST_VARS["FM2_PIN"] != "")) {    
      $UserID = CheckLogin($HTTP_POST_VARS["FM2_Number"], $HTTP_POST_VARS["FM2_PIN"]);
	  
	  if ($UserID == "-1") { $DisplayLoginBox = "YES"; }
	  else                 { $DisplayLoginBox = "NO";  }
    }  // if statement
	else {
	  $UserID          = "Empty Fields";
	  $DisplayLoginBox = "YES";
	}  // else statement
  }  // if statement
  
  if ($HTTP_POST_VARS["Submit"] == "Update Account") {
    $UserID = $HTTP_POST_VARS["UserID"];
	$DisplayLoginBox = "NO";
  }  // if statement

  //----------------------------------------------
  // Throw up our pretty HTML graphics and tables.
  //
  // This part is the same no matter what page
  // we are displaying.
  //----------------------------------------------

  echo "<table width=750 cellspacing=0 cellpadding=0 border=0 bgcolor=#264c73>\n";
  echo "<tr>\n";
  echo "<td width=182 valign=top align=center bgcolor=#264c73>\n";  
    
  echo "</td>\n";
  echo "<td width=46 align=right valign=top>\n";
  echo "<img src=\"curves.gif\" width=46 height=36 border=0><br>\n";
  echo "<img src=\"horiz_dots.gif\" width=46 height=850 border=0>\n";
  echo "</td>\n";
  
  echo "<td width=680 valign=top align=left>\n";
  echo "<img src=\"vert_dots.gif\" width=545 height=11 border=0><p>\n";  

  //---------------------------------------------------------------
  // Now we need to route the rest of our page via the QueryString.
  //--------------------------------------------------------------- 
 
  if ($HTTP_POST_VARS["Submit"] == "Login") {
	if ($UserID != "Empty Fields") {
	  if ($UserID == -1) {
	    echo "You have entered an invalid Follow Me/Find Me number<br>" .
	         "or PIN combination.  Please try again.<br><br>\n";
	  }  // if statement
	  else {
	    DisplayUserScreen($UserID);
	  }  // else statement
	}  // if statement
  }  // if statement
  elseif ($HTTP_POST_VARS["Submit"] == "Update Account") {
    UpdateAccount($UserID);
	DisplayUserScreen($UserID);
  }  // elseif statement
  elseif (($HTTP_POST_VARS["Submit"] == "Signup") || 
          ($HTTP_POST_VARS["Submit"] == "Create Account")) {
    DisplaySignupForm();
  }  // elseif statement

  if ($DisplayLoginBox == "YES") {
    echo "<FONT SIZE=1 FACE=\"Verdana, Arial, Helvetica, sans-serif\" COLOR=\"WHITE\">\n" . 
	     "<div align=left>If you already have a " . 
  	     " Follow Me/Find Me account number, then " . 
	     "please sign in below. Your number should be 10 digits, including the area code, " . 
		 "and take the form (800)1234567</FONT><p>\n";
    echo "<form action=\"" . $Path . 
  		 "fm2_login.php\" method=\"post\" name=\"LoginForm\">\n";
    echo "<TABLE>\n";
	echo "<TR><TD ALIGN=\"RIGHT\">\n<FONT SIZE=1 FACE=\"Verdana, Arial, Helvetica, sans-serif\" " .
		 "COLOR=\"WHITE\">number</FONT>&nbsp;&nbsp;</TD>\n<TD>\n<input type=text name=\"FM2_Number\" " .
		 "size=11 maxlength=15>\n</TD>\n</TR>\n";
    echo "<TR><TD ALIGN=\"RIGHT\">\n<FONT SIZE=1 FACE=\"Verdana, Arial, Helvetica, sans-serif\" " .
	     "COLOR=\"WHITE\">PIN</FONT>&nbsp;&nbsp;</TD>\n<TD>\n<input type=password name=\"FM2_PIN\" " .
		 "size=11 maxlength=6></TD>\n</TR>\n";
    echo "<TR><TD>&nbsp;</TD><TD><input type=submit name=\"Submit\" " .
		 "value=\"Login\"></TD></TR></TABLE>\n";

    echo "</form>";
  }  // if statement
  else {
    GreetTheUser($UserID);
    echo "<font size=2>&nbsp;&nbsp;to change users, logout</font>";
	echo "<form action=\"" . $Path . "fm2_login.php\" method=post name=\"Logout\">\n";
	echo "&nbsp;&nbsp;<input type=submit name=\"Submit\" value=\"Logout\">\n";
	echo "</form><p>\n"; 
  }  // else statement
  
  //------------------------------------------------
  // Intelligently display the Signup button
  // That is, if we are in the middle of signing up,
  // don't bother having the button there.
  //------------------------------------------------
  
  if (($HTTP_POST_VARS["Submit"] != "Signup") && 
      ($HTTP_POST_VARS["Submit"] != "Create Account")) { 
    echo "<NOBR><form action=\"" . $Path . 
  	     "fm2_login.php\" method=\"post\" name=\"SignupForm\">\n";  			   
    echo "<FONT SIZE=1 FACE=\"Verdana, Arial, Helvetica, sans-serif\" COLOR=\"WHITE\">&nbsp;&nbsp;otherwise, signup " . 
	     "<br>&nbsp;&nbsp;for a new account now.<br><br>&nbsp;</FONT>\n";
    echo "<input type=submit name=\"Submit\" value=\"Signup\"></form></NOBR>\n";
  }  // if statement

  
  echo "</td>\n";
  
  echo "</tr></table>\n";
}  // function DisplayMainScreen


//------------------------------------------------------------------------------------

DisplayMainScreen();

echo "</body></html>\n";

?>