/***************************************************************************
 *
 * wget.rexx -- Invoke Wget from WWW browser
 *
 * This program is copyrighted freeware. All rights reserved.
 * Copyright (C) 1998-2000 by Thomas Aglassinger <agi@sbox.tu-graz.ac.at>
 *
 * See http://www.giga.or.at/~agi/wgetrexx/ for more information.
 *
 **************************************************************************/

/*--------------------------------------------------------------------------
 * Some values you might want to change
 *------------------------------------------------------------------------*/

/* CLI Command to call as wget. If wget is not within the Workbench
 * search path, you can specify a full path here (for example,
 * 'Work:Net/wget') */
wget_command = 'wget'

/*--------------------------------------------------------------------------
 * Initialization
 *------------------------------------------------------------------------*/

/* Version information */
version = "$VER: wget.rexx 2.3 (18.6.2000)"

/* Install signal handlers */
SIGNAL ON Break_C                      /* Catch Control-C */
SIGNAL ON NoValue                      /* Catch unitinialized variables */

/* Enable retrieving of RESULT from external programs */
OPTIONS RESULTS

/* AmigaOS standard return codes (according to <rexx/errors.h>) */
RC_OK     = 0
RC_Warn   = 5
RC_Error = 10
RC_Fatal = 20

/*--------------------------------------------------------------------------
 * Handle CLI arguments passed by user
 *-------------------------------------------------------------------------*/

/* Set default values for CLI arguments */
to       = 'Web:'
ask      = 0
further  = 0
continue = 0
verbose  = 0
clip     = 'wget'
port     = ''
screen   = ''
options  = ''

/* Open rexxdossupport.library */
CALL open_library('rexxdossupport.library', 2)

/* Obtain CLI arguments */
PARSE ARG arguments

/* Parse CLI arguments */
template = "Verbose/S,To/K,Ask/S,Further/S,Port/K,Continue/S,Clip/K,Screen/K,Options/F"
IF ~ReadArgs(arguments, template) THEN DO
   CALL view_error_message(RC_Error, "Error in CLI options: " || Fault(RC) || "*NRefer to the manual about possible arguments.")
END

/* Show program header */
IF verbose THEN DO
    SAY 'wget.rexx -- Invoke Wget from WWW browser. Version ' || SUBWORD(version, 3)
    SAY 'Copyright © 1998-99 Thomas Aglassinger. Freeware.'
    SAY
END

/*--------------------------------------------------------------------------
 * Check basic requirements
 *-------------------------------------------------------------------------*/

/* Check, if wget is in search path */
ADDRESS COMMAND 'which >nil: wget'
IF RC ~= 0 THEN DO
    CALL view_error_message(RC_Error, "'Wget' must be installed within the Workbench search path.")
END

/* Check, if download directory is available */
download_directory = to
IF ~Exists(download_directory) THEN DO
    CALL view_error_message(RC_Error, "Cannot find download directory '" || download_directory || "'.*NThe directory must exist and be accessible.")
END

/*--------------------------------------------------------------------------
 * Assign browser port and commands
 *------------------------------------------------------------------------*/

/* Determine browser port */
browser.port = find_browser_port(port);
IF (browser.port = "") THEN DO
    /* No supported browser found. Abort with error message. */
    CALL view_error_message(RC_Error, "Could not find ARexx port of any supported browser.*NMake sure your browser is supported and running at*Nits default ARexx port or start script from browser.")
END
ELSE IF verbose THEN DO
    /* Tell the user which browser we are using */
    SAY "Using browser in port '" || browser.port || "'"
    SAY
END

/* Determine ARexx commands to be used for communication with browser */
IF LEFT(browser.port,4) = 'AWEB' THEN DO
    /* AWeb */
    browser.open = 'Open Reload'
    browser.query_uri = 'Get URL'
    browser.activate.count = 2
    browser.activate.1 = 'ActivateWindow'
    browser.activate.2 = 'WindowToFront'
END
ELSE IF LEFT(browser.port,7) = 'IBROWSE' THEN DO
    /* IBrowse */
    browser.open = 'GotoURL'
    browser.query_uri = 'Query URL'
    browser.activate.count = 2
    browser.activate.1 = 'Show'
    browser.activate.2 = 'ScreenToFront'
END

ELSE DO
    /* Unknown browser */
    CALL view_error_message(RC_Error, "Application in port '" || browser.port || "' is no supported browser*NRefer to the manual to learn which are.")
END

/* Check, if browser is available */
IF ~SHOW('P', browser.port) THEN DO
    /* No; abort with error message */
    CALL view_error_message(RC_Error, "Cannot find WWW browser in port '" || browser.port || "'.*NBrowser must be launched before this script.")
END

/*--------------------------------------------------------------------------
 * Ask for additional options
 *-------------------------------------------------------------------------*/
IF (ask) THEN DO
    /* Open rexxreqtools.library */
    CALL open_library('rexxreqtools.library', 0)

    IF further THEN DO
        /* Only further options are asked and the options passed in the
         * command line are not displayed in the requester */
        ask_options = ''
        options = options || ' '
        further_text = ' further '
    END
    ELSE DO
        /* Display options passed in the command line in the requester
         * so that the user can edit all of them */
        ask_options = options
        options = ''
        further_text = ' '
    END

    IF continue THEN DO
        /* Obtain options used to be displayed as default in requester
         * from the clip.
         *
         * Note that this can discard all options passed in the CLI if
         * <further> was not specified.*/
        ask_options = GetClip(clip)
    END
    ELSE DO
        /* Reset the Clip and use the options already in <ask_options>
         * as default requester content */
        SetClip(clip, "")
    END

    /* Redirect requester to specified screen */
    requester_tags = ''
    IF screen ~= '' THEN DO
        requester_tags = 'rt_pubscrname="' || screen || '"'
    END

    /* Ask for additional options. If the user cancels the requester,
     * abort the whole program. */
    ask_options = rtGetString(ask_options, "     Enter" || further_text || "options for Wget     ", "Wget.rexx Request",, requester_tags)
    IF (rtresult = 0) THEN DO
        EXIT 5
    END

    /* Update the clip with the options asked */
    SetClip(clip, ask_options)

    /* Append options just asked to overall options */
    options = options || ask_options
END /* ask */

/*--------------------------------------------------------------------------
 * Determine download URI and target directory
 *-------------------------------------------------------------------------*/

/* From now on talk with the browser */
ADDRESS VALUE browser.port

/* Figure out URI to download from */
IF (POS('http://', options) = 0) THEN DO
    /* There is no URI specified in the command line, therefore use the one
     * from page currently viewed in browser */
    browser.query_uri
    uri = RESULT

    /* Translate possible 'file://localhost/www.server.net/dir/file' to
     * 'http://www.server.net/dir/file' */
    PARSE VAR uri 'file://localhost/' (download_directory) local_uri
    IF (local_uri ~= "") THEN DO
        uri = 'http://' || local_uri

    END
END
ELSE DO
    /* Extract URI from options */
    PARSE VAR options options1 'http://' uri ' ' options2

    uri = 'http://' || uri
    options = options1 || ' ' || options2
END

/* Check, if there is another URI within the options.
 * In case, abort with error message. */
IF (POS('http://', options) > 0) THEN DO
    CALL view_error_message(RC_Error, "Cannot download from more than one URI at a time*NAll but one URIs must be removed.")
END

/* Extract the name of the WWW server to be downloaded from */
PARSE VAR uri 'http://' server '/' external_file

/* Validate URI */
IF server = '' THEN DO
    /* If the server name could not be extracted,
     * view error message and abort */
    CALL view_error_message(RC_Error, "Cannot find server name in URI*NURI must start with ""http://""")
END

/* Make sure that download_directory ends in ':' or '/' */
IF (POS(RIGHT(download_directory, 1), ':/') = 0) THEN DO
    download_directory = download_directory || '/'
END

/* Compute target directory and filename in URI-style */
target_directory = convert_amiga_path_to_uri(download_directory)
target_file = 'file://localhost/' || download_directory || server
target_file = target_file || '/' || convert_uri_to_amiga_path(external_file)

/*--------------------------------------------------------------------------
 * Invoke Wget
 *------------------------------------------------------------------------*/

/* View source and target file for users information */
IF verbose THEN DO
    SAY 'Downloading "' || uri || '"'
    SAY 'to          "' || target_file || '"'
    SAY
END

/* Compute command call for wget */
wget_command = wget_command || ' -x --directory-prefix=' || target_directory
wget_command = wget_command || ' ' || options || ' "' || uri || '"'

/* View the command so the user knows what is going to happen */
SAY wget_command
SAY

/* Invoke the command viewed before and remember its returncode */
ADDRESS COMMAND wget_command
wgetRC = RC

/*--------------------------------------------------------------------------
 * View downloaded page in browser and exit
 *------------------------------------------------------------------------*/
IF (wgetRC = 0) THEN DO
    SAY
    SAY 'Successfully downloaded data to local web.'

    IF SHOW('P', browser.port) THEN DO
        SAY 'Viewing page in Browser'

        /* In case browser has been iconified meanwhile, pop it up again */
        DO command_index=1 FOR browser.activate.count
            browser.activate.command_index
        END

        /* View page from local web */
        browser.open || ' "' || target_file || '"'
    END
END
ELSE DO
    /* Inform user that something has gone wrong */
    SAY
    SAY 'Error during download. Nothing to display in Browser.'
    CALL view_error_message(0, "Wget did return an error")
END

/* Exit with code returned by wget, multiplied by 10
 * (wget returns 1 in case of error) */
EXIT 10*wgetRC

/*--------------------------------------------------------------------------
 * Signal handlers
 *------------------------------------------------------------------------*/

/* Handler for Control-C */
Break_C:
    SIGNAL OFF Break_C
    SAY
    SAY 'wget.rexx: interrupted by user.'
    EXIT 5

/* Handler for uninitialized variables */
NoValue:
    SIGNAL OFF NoValue
    SAY '--------------------------------------------------------------------------'
    SAY 'wget.rexx: stopped because of bug.'
    SAY
    SAY 'Please report the text below to the email address mentioned in the manual,'
    SAY 'so the bug can be fixed in a future release.'
    SAY
    SAY 'version="' || version || '"'
    SAY 'browser="' || browser.port || '"'
    SAY 'uri    ="' || uri || '"'
    SAY 'options="' || arguments || '"'
    SAY 'source ="' || SIGL || ' ' || SourceLine(SIGL) || '"'
    SAY 'reason = uninitialized variable'
    SAY '--------------------------------------------------------------------------'
    EXIT 20

/*--------------------------------------------------------------------------
 * Subroutines
 *------------------------------------------------------------------------*/

/***************************************************************************
 * NAME
 *   find_browser_port -- Find Arexx port of any supported browser.
 * FUNCTION
 *   If a port has been passed to this function as argument, it will also
 *   be the result.
 *
 *   If the port argument is an empty string, it is assumed that the host
 *   the script was started from is a browser.
 *
 *   If this turns out to be wrong, the list of ports in the system is
 *   scanned for default ARexx ports of any of the supported browsers.
 *
 *   If no such browser could be found
 * INPUTS
 *   port - Default port to be used.
 * RESULT
 *   Name of the ARexx port of any supported browser currently running.
 *   An empty string ("") indicates that no browser was running.
 **************************************************************************/
find_browser_port: PROCEDURE
    PARSE ARG port

    IF (port = "") THEN DO
        /* Assume that current host is a browser */
        port = ADDRESS()

        IF ((LEFT(port, 4) ~= 'AWEB') ,
             | (LEFT(port, 7) ~= 'IBROWSE')) ,
        THEN DO
            /* Current host has turned out to be useless (e.g. 'REXX' if started
             * from a plain CLI), therefore try to find the default port of any
             * of the supported browsers */
            IF SHOW('P', 'AWEB.1') THEN DO
                port = 'AWEB.1'
            END
            ELSE IF SHOW('P', 'IBROWSE') THEN DO
                port = 'IBROWSE'
            END
            ELSE DO
                /* No supported browser found. Return empty string to
                 * indicate this. */
                port = ""
            END
        END
    END

    RETURN port

/***** ugly/convert_amiga_path_to_uri **************************************
 * NAME
 *   convert_amiga_path_to_uri -- Convert path from Amiga to URI style
 * FUNCTION
 *   Convert path from Amiga to URI style. The following conversion rules
 *   are applied:
 *
 *   - Device names are transformed from e.g. "ram:" to "/ram/"
 *   - Leading "/"'s replaced by "../"
 *   - All "//"'s are replaced by "/../"
 * INPUTS
 *   amiga_path - Amiga style path
 * RESULT
 *   Path in URI style
 * BUGS
 *   The input path is not validated for correctness. In such a case the
 *   result will also be invalid.
 * EXAMPLES
 *   "ram:"           -> "/ram/"
 *   "ram:sepp"       -> "/ram/sepp"
 *   "sepp//resi"     -> "sepp/../resi"
 *   "ram:sepp//resi" -> "/ram/sepp/../resi"
 *   "//resi/hugo"    -> "../../resi/hugo"
 *   "//resi//hugo"   -> "../../resi/../hugo
 **************************************************************************/
convert_amiga_path_to_uri : PROCEDURE
    PARSE ARG amiga_path

    uri = ''

    /* Extract device name from Amigapath (if there is any) */
    device = ''
    IF (POS(':', amiga_path) > 0) THEN DO
        PARSE VAR amiga_path device ':' path_part
        amiga_path = path_part
    END

    /* Convert leading "/" to "../" */
    DO WHILE (LEFT(amiga_path, 1) = '/')
        amiga_path = DELSTR(amiga_path, 1, 1)
        uri = uri || '../'
    END

    uri = uri || amiga_path

    /* Convert '//' inside string to '/../' */
    DO WHILE (POS('//', uri) > 0)
        PARSE VAR uri before '//' after
        uri = before || '/../' || after
    END

    /* Add device name in Unix-style;
     * 'ram:' becomes '/ram/' */
    IF (device ~= '') THEN DO
        uri = '/' || device || '/' || uri
    END

    RETURN uri

/***** ugly/convert_uri_to_amiga_path **************************************
 * NAME
 *   convert_uri_to_amiga_path -- Convert path from URI to Amiga style
 * SYNOPSIS
 *   amiga_path = convert_uri_to_amiga_path( uri )
 * FUNCTION
 *   Convert path from URI to Amiga style. The following conversion rules
 *   are applied:
 *
 *   - Replace every leading '../' by '/'
 *   - Replace every '/../' by '//'
 *   - Replace every '~' by '%7E'
 * INPUTS
 *   uri - URI style path
 * RESULT
 *   amiga_path - Amiga style path
 * BUGS
 *   The input path is not validated for correctness. In such a case the
 *   result will also be invalid.
 *
 *   Devices in URI style are not handled.
 **************************************************************************/
convert_uri_to_amiga_path : PROCEDURE
    PARSE ARG uri

    amiga_path = ''

    /* Replace leading "../" by "/" */
    DO WHILE (LEFT(uri, 3) = '../')
        uri = DELSTR(uri, 1, 3)
        amiga_path = amiga_path || '/'
    END

    amiga_path = amiga_path || uri

    /* Replace '/../' inside string by '//' */
    DO WHILE (POS('/../', uri) > 0)
        PARSE VAR uri before '/../' after
        uri = DELSTR(uri, POS('/../', uri), 4)
        amiga_path = before || '//' || after
    END

    /* Replace '~' by '%7E' */
    DO WHILE (POS('~', uri) > 0)
        PARSE VAR uri before '~' after
        uri = DELSTR(uri, POS('~', uri), 1)
        amiga_path = before || '%7E' || after
    END

    RETURN amiga_path

/***************************************************************************
 * NAME
 *   view_error_message -- Pop-up error requester.
 * FUNCTION
 *   Pop-up error requester and wait for user to confirm it.
 *
 *   The title of the requester is "Wget.rexx Error", and the confirmation
 *   button will have an "Ok".
 *
 *   Optionally it can abort the script with a return code.
 * INPUTS
 *   return_code - Optional return code if the procedure should EXIT after
 *                 viewing the message. Specify 0 (or RC_Ok) if is should
 *                 return to the calling environment.
 *   message     - Message text to be in body of requester.  This text must
 *                 not contain any double quotes ("), but single quotes (')
 *                 are allowed.
 * RESULT
 *   The return value is the same as sent by the RequestChoice command.
 *   Normally, this is 0, as there is only one button. Other values indicate
 *   an error while invoking RequestChoice.
 * NOTES
 *   This procedure simply invokes c:RequestChoice with the proper
 *   arguments.
 **************************************************************************/
view_error_message : PROCEDURE
    PARSE ARG return_code, message
    ADDRESS COMMAND 'RequestChoice >nil: "Wget.rexx Error" "' || message || '" Ok'

    IF (return_code > 0) THEN DO
        EXIT return_code
    END

    RETURN RC

/****** ugly/open_library **************************************************
 * NAME
 *   open_library -- Open library or view error requester if not found.
 * FUNCTION
 *   Open a library using AddLib().
 *
 *   If the library can not be found, view a requester that says so and
 *   abort the program with an exit code of 20.
 * INPUTS
 *   library - Name of the library to open
 *   version - Minimum library version (0 for any)
 * RESULT
 *   If this function returns, everything was ok.
 **************************************************************************/
open_library: PROCEDURE
    PARSE ARG library, version

    IF ~SHOW('L', library) THEN DO
        IF ~ADDLIB(library, 0, -30, version) THEN DO
            message = "Library '" || library "'"
            IF (version > 0) THEN DO
                message = message || " version " || version
            END
            message = message || " not found.*NRefer to the manual where to obtain it from."
            CALL view_error_message(RC_Fatal, message)
        END
    END

    RETURN

