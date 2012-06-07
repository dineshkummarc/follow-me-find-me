// ----------------------------------------------------------------------------------
//
// ---------------------------------------------------
// copyright 2000 by voxeo corporation. (see LGPL.txt)
//
// v1.1 Coded in ASP
// v1.1 Coded by Ryan Campbell and Stephen J. Lewis
// --------------------------------------------------- 
//
//  Follow Me / Find Me (FM2) is an application that allows a user
//  to with several personal contact numbers to establish one  
//  number that will automatically attempt to reach that user at 
//  those numbers.  For example a user may wish to be contacted at their
//  desk, their cell phone, and/or via a main office number.  With a 
//  Follow Me / Find Me service the user would only need to give out one number.
//
//
// This application uses Active Server Pages (ASP) to access a backend SQL database and
// to dynamically generate CallXML
//
// The entire suite contains 22 files, 3 optional files, and 1 subdirectory:
// ------------------------------------------------------------------------------------
//      FM2.MDB	                        a sample database in MSAccess
//      fm2_admin.asp	
//      fm2_admin_add_number.asp        allows a user to add a number to their list
//      fm2_admin_change_greeting.asp   allows user to record a personal greeting
//      fm2_admin_change_number.asp     allows a user to change a number in their list
//      fm2_admin_change_order.asp      allows a user to change the order of a number in 
//                                      their list
//      fm2_admin_change_PIN.asp        allows a user to change their PIN code
//      fm2_admin_change_vm_number.asp  allows a user to change their voicemail number
//      fm2_admin_delete_number.asp     allows a user to delete a number from their list
//      fm2_admin_enable.asp            allows a user to toggle any boolean value based on
//                                      the variables sent to this file
//      fm2_admin_global_properties.xml implements the global properties menu where user can 
//                                      set additional preferences
//      fm2_admin_menu.xml              implements basic admin menu where user can set 
//                                      preferences
//      fm2_admin_move.asp	
//      fm2_admin_number_config.asp     implements number configuration menu
//      fm2_admin_verify_PIN.asp        verifies account login
//      fm2_Call_and_VM.asp             routes outbound calls based on the variables sent to 
//                                      this file
//      fm2_db.asp                      file used to save data to the FM2 database 
//      fm2_main.asp                    main file which greets the caller
//      fm2_parallel_sessionfilter.asp  handles the actual conferencing of two calls in
//                                      parallel mode
//      fm2_parallel_outbound.asp       handles the actual calling used in conferencing
//                                      for parallel mode
//      fm2_user_acceptance.asp         allows the user to accept an incoming call or direct 
//                                      to voicemail
//      subs.asp                        contains general subroutines used by several of the 
//                                      .asp files
//
//      optional file:
//      --------------
//      fm2_login.php                   this is the optional web-front end for Follow Me/Find
//                                      Me.  it is coded in PHP, not ASP, and is not intended
//                                      as a fully functioning administrative tool.  see 
//                                      below for more details.
//      database-win32.inc              PHP abstracted database library for windows 32 systems
//                                      (uses ODBC)
//      database-linux.inc              PHP abstracted database library for unix/linux
//                                      (uses interbase)
//
//      subdireectory:
//      --------------
//      [audio directory]               this directory contains all of the sample audio files
//
// 
// The database is an ODBC resource named FM2
// and contains two tables "FM2_numbers" and "Users" described below.
//
// FM2_numbers - this table contains the number(s) to dial for outbound calls
// --------------------------------------------------------------------------
//      ID                      AutoIncrement   identity
//      User_ID                 Number          ID of user that this number belongs to
//      Num_Order               Number          the order that this number appears in the
//                                              user's list of numbers
//      Dial_number             text            the number to dial
//      Enabled                 boolean         is this number currently active?
//
// Users - stores user information
// -------------------------------
//      First                   text            first name
//      Last                    text            last name
//      Middle                  text            middle name
//      ID                      AutoIncrement   user ID
//      phone_number            text            contact phone number
//      voicemail_number        text            number to use for voicemail
//      email_address           text            contact email address
//      FAX                     text            contact FAX number
//      PIN                     text            PIN code
//      address1                text            first address line
//      address2                text            second address line
//      city                    text            city
//      state                   text            state
//      zip                     text            zip code
//      vm_on_no_answer         boolean         send the caller to voicemail if 
//                                              the user doesn't answer?	
//      pin_verification        boolean         require PIN verification to accept 
//                                              FM2 call?
//      pin_readback            boolean         readback the  PIN to make sure the 
//                                              user entered it correctly?
//      mode                    integer         FM2 mode 1=sequentially dial the numbers 
//                                              2=dial all of the numbers at once
//      fm2_enabled             boolean         is the service turned on?
//      greetingfile            text            file to use for personalized greeting
//
//
//  Several important steps to remember when administering this application:
//  ------------------------------------------------------------------------
//  (1) In the fm2_main.asp file, there is are three callXML variables assigned
//      relating to paths.  The default values will simply not work on your server
//      unless you change the paths to reflect where you are storing the files.
//  (2) In the subs.asp file are the functions that determine your HTTP, FTP, and
//      ODBC usernames and passwords.  Again, the default values there may not be
//      correct for your specific server.  FTP is not necessary to run 95% of 
//      Follow Me/Find Me; however, if you want to allow users to change their
//      greeting file, then you will need to allow FTP access.  
//  (3) Follow Me/Find Me attempts to save greeting files under a directory that is
//      the same as the  called-id of the user account.  Follow Me/Find Me does NOT
//      automatically create this folder/directory, which means if it isn't set up
//      through an administrative tool (web page, etc.), then the FTP will fail when
//      it tries to save greeting files there.  Again, this is only important if you
//      wish to allow dynamic greeting files configurable by the user.
//  (4) The web-front end for Follow Me/Find Me (fm2_login.php) does not tie into the 
//      voxeo provisioning system.  It merely creates a valid database entry and allows 
//      users to change their voicemail, outbound numbers, and etc.  If you have 
//      provisioned a number from http://community.voxeo.com to point to Follow Me/Find 
//      Me (fm2_main.asp), the application will not be able to find that user until a 
//      database entry has been made.  fm2_login.php is intended purely as a demonstration
//      of an administrative front-end.
//  (5) The web-front end for Follow Me/Find Me (fm2_login.php) does not currently 
//      create the necessary user directories for FTPing greeting files for individual
//      users.  As mentioned in points 4 and 5, this requires an extra administrative
//      step, but could clearly be added to the code itself.
//  (6) Note also that the web-front end (fm2_login.php) is coded in PHP and not ASP.
//      PHP must be added to your webserver (unlike ASP, which comes with IIS if you
//      are running a Win32 host).  You can download the PHP opensource scripting engine
//      from http://www.php.net.
// -------------------------------------------------------------------



