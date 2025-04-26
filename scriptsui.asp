<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>Scripts UI</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" language="JavaScript" src="/validator.js"></script>
<script>

var custom_settings = <% get_custom_settings(); %>;

/* Function to get the results created / output put to a results.js (text) file from the selected script */
function get_results_data(){
    var h = 0;
    $.ajax({
        url: '/ext/scriptsui/results.js',
        timeout: 3000,
        dataType: 'text',
        error: function(xhr){
           /*  alert('ajax read results.txt status: ' + xhr.status + ' Status Text: ' + xhr.statusText + ' Response ' + xhr.responseText); */
           document.getElementById("textarea").innerHTML = "Error reading /www/ext/scriptsui/results.js file - check/debug your script and try again"
        },
        success: function(response){
            var resultString = htmlEnDeCode.htmlEncode(response.toString());
            document.getElementById("textarea").innerHTML = resultString; 
        }
    });
}

function SetCurrentPage() {
    /* Set the proper return pages */
    document.form.next_page.value = window.location.pathname.substring(1);
    document.form.current_page.value = window.location.pathname.substring(1);
}

/* Function to prepare and show html menu of selectable options and show generated results from selection */
function  initial(){

        SetCurrentPage(); 

        show_menu();
}

/* Function to run the script selected from menu and return the results generated from the script */
function runScript(row){
        /* Access row data user the data-* attributes */
        const name = row.parentNode.parentNode.dataset.name;
        const script = row.parentNode.parentNode.dataset.path;

        /* Apply name of script to run to the forms "action_script" value - limit of 14 characters  */
        /*+ Note - if i used "start_scriptsui" in the name of action_script, the service-event would not fire */
        var action_script_val = "start_scrptsui" + name;
        document.frmScript.action_script.value=action_script_val;
        showLoading(1);
        document.frmScript.submit();
        
        /* Display running script message while waiting for the selected script to run */
        document.getElementById("textarea").innerHTML = "Waiting about 5 seconds for script " + script + " to complete" ; 

        /* Once the form has been submitted, the services-event fires and calls the script launcher.
           To allow for the system event to fire and the script to complete running and write a results file, 
           wait about 5 seconds, then go read in the results into the Custom page text box */
        setTimeout(get_results_data,5000);

}
 
</script>

                            
</head>
<body onload="initial();"  class="bg">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="current_page" value="scriptsui.asp">
<input type="hidden" name="next_page" value="scriptsui.asp">
<input type="hidden" name="group_id" value="">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_wait" value="5">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="action_script" vlaue="">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<input type="hidden" name="amng_custom" id="amng_custom" value="">

<table class="content" align="center" cellpadding="0" cellspacing="0">
<tr>
<td width="17">&nbsp;</td>
<td valign="top" width="202">
<div id="mainMenu"></div>
<div id="subMenu"></div>
</td>
<td valign="top">
<div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
<tr>
<td align="left" valign="top">
<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
<tr>
<td bgcolor="#4D595D" colspan="3" valign="top">
<div>&nbsp;</div>
<div class="formfonttitle">Tools - Scripts UI</div>
<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
<div class="formfontdesc">My list of scripts - select which to run by clicking on the RUN SCRIPT button</div>

<table id="myTable" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
        <tr>
                <th>Command</th>
                <th>Path</th>
                <th>Action</th>
        </tr>
        <tbody>
        <script> 
                $(document).ready(function () { 
  
                    // FETCHING DATA FROM JSON FILE 
                    $.getJSON("user/scriptsui/scriptsui.json", function (data) { 
                        var script = ''; 
  
                        // ITERATING THROUGH OBJECTS 
                        $.each(data, function (key, value) { 
  
                            //CONSTRUCTION OF ROWS HAVING 
                            // DATA FROM JSON OBJECT 
                            script += '<tr data-name="' + value.name + '" data-path="' + value.path + '">' 

                            script += '<td>' + value.name + '</td>'; 
  
                            script += '<td>' + value.path + '</td>';
                            
                            script +='<td><button type="button" onclick="runScript(this)">Run Script</button></td>'; 
  
                            script += '</tr>'; 
                        }); 

                        script += '</tbody>'
                          
                        // INSERTING ROWS INTO TABLE
                        $('#myTable').append(script); 
                    }); 
                }); 
        </script> 
</table>
<div style="margin-top:8px">
        <textarea cols="63" rows="27" wrap="off" readonly="readonly" id="textarea" class="textarea_ssh_table" style="width:99%; font-family:'Courier New', Courier, mono; font-size:11px;"></textarea>
</div>
</form>

</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
<td width="10" align="center" valign="top"></td>
</tr>
</table>
<form method="post" name="frmScript" action="/start_apply.htm" target="hidden_frame">
	<input type="hidden" name="productid" value="<% nvram_get("productid"); %>">
	<input type="hidden" name="current_page" value="">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="action_mode" value="apply">
	<input type="hidden" name="action_script" value="">
	<input type="hidden" name="action_wait" value="">
</form>
<div id="footer"></div>
</body>
</html>