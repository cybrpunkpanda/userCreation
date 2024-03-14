

Write-Host "#########################################################################################################"
Write-Host "##"
Write-Host "##"
Write-Host "## User Creation Tool"
Write-Host "##"
Write-Host "## By: Devrryn Jenkins"
Write-Host "##"
Write-Host "##"
Write-Host "#########################################################################################################"

write-host -ForegroundColor White -BackgroundColor Cyan "Welcome to the User Creation Tool for <YOUR_ORG>!"
Write-Host ""
write-host "First, we are going to add the user to Active Directory. You will be asked if you would like to"
write-host "copy a user or start from scratch. Most of the time you will be copying a user!"
Write-Host ""
write-host ""
write-host -BackgroundColor Red -ForegroundColor White "NOTE: YOU NEED TO HAVE RSAT AND ACTIVE DIRECTORY MODULE INSTALLED FOR THIS TOOL TO WORK!" 
write-host ""

read-host "Press enter to continue..."
## Secure String global password variable for later use. DO NOT SHARE THIS SCRIPT WITH YOUR PASSWORD IN IT (Unless you're feeling...adventurous). Probably not recommended to hard code.
$pass = ConvertTo-SecureString "<PASSWORD>" -asplaintext -force


while ($true){

   ## Technician inputs the SAMAccountName of the user we are copying over.
   $usercopy = read-host "Ok, What is the users login name that we will be copying?"
   ## An error returns the user to SAMAccountName entry if the entry from the user does not match a user in the forest
   Try {

   $refuser = Get-aduser $usercopy -properties * -ErrorAction Stop
   
   break
  
  } catch {

  write-host -backgroundcolor red -foregroundcolor white "Uh oh...that user does not exist. Try again."
  write-host -backgroundcolor red -foregroundcolor white "The user may be under a different SAMAccountName than expected."
 
  } 


  }
  

   Write-Host -backgroundcolor yellow -foregroundcolor black "Ok. Now we are going to input information for the New User we are creating!"
      
   $usersam = read-host "What is the users SAMAccountName? (This would be their login name)"
   $userfirst = read-host "What is the Users first name?"
   $userlast = read-host "What is the Users last name?"
   $fullname = $userfirst + " " + $userlast
   write-host ""
   write-host -BackgroundColor Red -ForegroundColor White "Please review and triple check the name and spelling above. Make sure the SAMAccountName is the"
   write-host -BackgroundColor Red -ForegroundColor White "users login name (usually first inital last name). Make sure the users name is spelled correctly."
   Write-Host -BackgroundColor Red -ForegroundColor White "You will have to delete the user and restart the process if there is an error"
   Write-Host ""
   read-host "Press enter to continue"

   New-ADuser -Name $fullname -GivenName $userfirst -Surname $userlast -DisplayName $fullname -SAMAccountname $usersam -AccountPassword $pass -Enabled $true -ChangePasswordAtLogon $true

   Write-Host "Copying..."

   get-aduser -identity $usercopy -properties * | select-object -expandproperty MemberOf | Add-ADGroupMember -members $usersam
   Write-Host ""
   Write-Host "Group Membership Addition Success!"
   Write-Host ""
   Set-aduser $usersam -City $refuser.City
   Write-Host ""
   write-host "City Copy Success!"
   Write-Host ""
   set-aduser $usersam -StreetAddress $refuser.StreetAddress
   Write-Host ""
   Write-Host "Street Address Success!"
   Write-Host ""
   set-aduser $usersam -State $refuser.State
   Write-Host ""
   Write-Host "State Success!"
   Write-Host ""
   set-aduser $usersam -Department $refuser.Department
   Write-Host ""
   Write-Host "Department Success!"
   Write-Host ""
   set-aduser $usersam -Company $refuser.Company
   Write-Host ""
   Write-Host "Company Success!"
   Write-Host ""
   set-aduser $usersam -PostalCode $refuser.PostalCode
   Write-Host ""
   Write-Host "Zipcode Success!"
   Write-Host "" 
   set-aduser $usersam -UserPrincipalName ($usersam + "<YOUR_ORG_DOMAIN>")
   Write-Host ""
   Write-Host "UPN Name Success!"
   Write-Host ""
   set-aduser $usersam -ProfilePath "\\<YOUR_USERS_SHARE>\roaming$\$usersam"
   Write-Host ""
   Write-Host "Roaming Profile Path Success!"
   Write-Host ""
   set-aduser $usersam -HomePage $refuser.HomePage
   Write-Host ""
   Write-Host "Web Page Set!"

   ## Descriptions may vary from the copied user, so this is the technicians time to either say it will be copied or not
   $desc = Read-Host "Will this user have the same Description as the user you copied?(y or n)"
        if ($desc -eq "y"){
        set-aduser $usersam -Description $refuser.Description
        } elseif ($desc -eq "n") {
        $setdesc = read-host "Ok then, what will the users description be?"
        set-aduser $usersam -Description $setdesc -Title $setdesc
        }
   Write-Host ""
   Write-Host "Description and Title Success!"
   Write-Host ""
   set-aduser $usersam -Office $refuser.Office
   Write-Host ""
   Write-Host "Office Location Success!"
   Write-Host ""
   ## This operates much like the description section does
   $phone = Read-Host "Will the Users Phone Number be the same as the business number or user we are copying? Choose 'c' if you do not know the users Phone number yet. (y or n or c)"
     
   ## Sales people generally have dedicated numbers and so do *some* staff. We differentiate that here. 
   if ($phone -eq "y") {
        set-aduser $usersam -OfficePhone $refuser.OfficePhone
        
        
        } elseif ($phone -eq "n") {

        Write-Host "Ok then, what will there phone number be? Please use a hyphen in the proper places"
        write-host "Example: 301-366-9875"
        $number = Read-Host "Number:"
        set-aduser $usersam -OfficePhone "$number"
       
        }

   Write-Host ""
   ## Setting the Domain and email address.
   $email = Read-Host "What will the users email domain be? Ex.: <IF_MULTIPLE_DOMAINS_INSERT_DOMAINS> "

   $emailentry = "$usersam" + "$email"

   set-aduser $usersam -EmailAddress $emailentry 

 $ou = Read-Host "Should the new user be in the same OU as the user you copied? (y or n)"

   if ($ou -eq "y") {
        $target = (Get-aduser $usercopy).distinguishedName.Split(',',2)[1]

        get-aduser $usersam | Move-ADObject -TargetPath $target


   } elseif ($ou -eq "n"){
        
       while ($true) {
        
       $ouchoice = read-host "Oh ok...which OU are we sending this user to then?"
       
       try {
       
        $targetOU = (Get-ADOrganizationalUnit -SearchBase <ADD_OUs_TO_SEARCH_THROUGH> 

        get-aduser $usersam | Move-ADObject -TargetPath $targetOU -ErrorAction Stop
        
        break
       
       } catch {
       
        Write-Host "Doesn't look like that's an existing OU. Try again" 

   }
   }
   }


   $email = Read-Host "Will this user require an email address? (y or n)"

   if ($email -eq 'y') {

   Write-host -BackgroundColor Yellow -ForegroundColor Black "Ok! Now we move on to mailbox creation!"
   Write-host -BackgroundColor Yellow -ForegroundColor Black "Next you will be asked to put in the login credentials for the server"

   read-host "Press enter to continue"
 
 while ($true) {

   $creds = Get-Credential

   Write-host -BackgroundColor Yellow -ForegroundColor Black "Ok! Now we are going to create the session"

   try {

   $sesh = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://<YOUR_ORGS_URI>/Powershell -Authentication Kerberos -Credential $creds -ErrorAction Stop

   Import-PSSession $sesh -DisableNameChecking -ErrorAction stop

   break

   } catch {

   Write-Host -BackgroundColor Red -ForegroundColor White "Uh oh. It looks like the password or username is incorrect for accessing the server. Try again!"

   }
   } 


   write-host ""
   Write-host -BackgroundColor Yellow -ForegroundColor Black "We're in! Ok, now we are going to create the mailbox"
   write-host ""
   Write-Host -BackgroundColor Yellow -ForegroundColor Black "Once you press enter the mailbox creation process will begin"

   read-host "Press enter to continue"

   Enable-Mailbox -identity $usersam 

   Write-Host "Mailbox Enabled!"
   Write-Host ""
   Write-Host "Disconnecting from server!"

   Remove-PSSession $sesh

   Write-Host -BackgroundColor Yellow -ForegroundColor Black "User Created w/ an active mailbox!! Congrats!!"
   
   } else { 

   Write-Host -BackgroundColor Yellow -ForegroundColor Black "User Created! Congrats!! (No email inbox was set up)"
}


Add-Type -AssemblyName PresentationFramework

$discbox = [System.Windows.MessageBox]::Show('Done! The user has been created!','Input','Ok')

 switch ($discbox) {

  'Ok' {

   Write-Host "All done!!"

   }
   }
  

   

