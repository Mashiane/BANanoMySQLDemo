B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=7.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private App As UOENowApp
	Private BANano As BANano		'ignore
	Private mysql As UOENowMySQL
	Private fName As String
End Sub

'build the modal for activities (called from another screen)
Sub SignIn(thisApp As UOENowApp) As UOENowModal
	App = thisApp
	Dim mdl As UOENowModal
	mdl.Initialize(App,"signinm","",False,"")
	mdl.AddTitle("BANanoMySQL Demo")
	mdl.CenterHeading
	mdl.LargeSize
	mdl.AddClose
	 
	Dim vt As UOENowVerticalTabs
	vt.Initialize(App,"vt",App.EnumThemes.Primary,"","")
	vt.AddItem("login","Log In","",False,True,LoginContainer)
	vt.AddItem("register","Register","",False,False,RegisterContainer)
	vt.AddItem("forgot","Forgot Password","",False,False,ForgotPassword)
	vt.AddItem("reset","Reset Password","",False,False,ResetPassword)
	vt.AddItem("changepwd","Change Password","",False,False,ChangePwdContainer)
	mdl.Body.AddVerticalTabs(0,0,vt)
	Return mdl
End Sub

Sub ChangePwdContainer() As UOENowContainer
	Dim rc As UOENowContainer
	rc.Initialize(App,"changerc",False,"","","")
	Dim frm As UOENowForm
	frm.Initialize(App,"form_changepassword","")
	frm.Form.AddRows(8).AddColumns12
	frm.Form.AddParagraph(1,1,"","Please enter all the information required here so that we can change your password.","","",True)
	frm.Form.AddTextBox(2,1,"change_email","","Email Address","fas fa-envelope","","","","","",False)
	frm.Form.AddPassword(3,1,"change_oldpassword", "","Old Password","fas fa-lock-open","","","","","",False)
	frm.Form.AddPassword(4,1,"change_newpassword", "", "New Password","fas fa-lock-open","","","","","",False)
	frm.Form.AddPassword(5,1,"change_confirmpassword", "", "Confirm New Password","fas fa-lock-open","","","","","",False)
	frm.Form.AddCheckBox1(6,1,"change_notrobot","I'm not a robot","confirm","","","",False,False,False,CreateMap("padding-bottom":"15px"))
	frm.Form.AddHorizontalRule(7,1)
	Dim btnRegister As UOENowButton
	btnRegister.Initialize(App,"btnChangePassword","Change Password","","","",App.EnumThemes.Primary,"","")
	btnRegister.FullWidth = True
	btnRegister.IsOutline = True
	btnRegister.IsPill = True
	frm.Form.AddButton(8,1,btnRegister)
	rc.AddForm(0,0,frm)
	Return rc
End Sub

Sub btnChangePassword_click(e As BANanoEvent)
	Dim data As Map = App.Form2Map("form_changepassword")
	Dim bRequired As Boolean = App.RequiredMap(data)
	If bRequired Then
		'we have missing fields, inform user
		App.ToastError("All the content to change your password is compulsory. Also ensure you confirm you are not a robot!")
		Return
	End If
	'we need to read the user details using the email address first
	Dim udata As Map = App.MapRemovePrefix(data,"change_")
	'the new password and confirm password should match
	Dim snewpassword As String = udata.Get("newpassword")
	Dim sconfirm As String = udata.Get("confirmpassword")
	Dim semail As String = udata.Get("email")
	Dim soldpassword As String = udata.Get("oldpassword")
	If snewpassword.EqualsIgnoreCase(soldpassword) Then
		App.ToastError("The new password and the old password should not match, please change the new password!")
		App.MarkInValid("change_oldpassword")
		App.MarkInValid("change_newpassword")
		Return
	End If
	If snewpassword <> sconfirm Then
		App.ToastError("The new password and its confirmation do not match, please rectify this first to continue!")
		App.MarkInValid("change_newpassword")
		App.MarkInValid("change_confirmpassword")
		Return
	End If
	'get the details of this email from the server
	'read the details of the user from the db, we need the current password
	mysql.Initialize
	App.Pause("#form_changepassword")
	Dim sqldata As String = mysql.SelectWhere("users", Array("firstname","password"), CreateMap("email":semail), Array("id"))
	Dim res As String = BANano.CallInlinePHPWait("BANanoMySQL",CreateMap("data":sqldata))
	'get the response from MySQL
	Dim resp As Map = App.json2map(res)
	Dim sresp As String = resp.Get("response")
	Dim recs As List = resp.Get("data")
	If sresp = "OK" Then
		'read the record
		Dim user_rec As Map = recs.Get(0)
		Dim sName As String = user_rec.Get("firstname")
		Dim spwd As String = user_rec.Get("password")
		'compare passwords
		If spwd.EqualsIgnoreCase(soldpassword) = False Then
			'the passwords do not match, irrespectibe of case
			App.Resume("#form_changepassword")
			App.ToastError("The Old passwords do not match, please ensure these match, to get your old password go to the Forgot Password section!")
			Return
		End If
		'the passwords match, update the password
		'update the database record with the new password
		Dim nrec As Map = CreateMap("password":snewpassword)
		' generate sql json detail
		mysql.Initialize
		Dim sqldata As String = mysql.UpdateWhere("users", nrec, CreateMap("email":semail))
		Dim res As String = BANano.CallInlinePHPWait("BANanoMySQL",CreateMap("data":sqldata))
		'get affected records
		Dim resp As Map = App.json2map(res)
		Dim strresp As String = resp.Get("response")
		Dim affectedRows As Int = resp.Get("data")
		App.Resume("#form_changepassword")
		If strresp = "OK" And affectedRows = 1 Then
			BANano.CallSub(pgindex,"HideSignIn", Null)
			App.SweetModalSuccess("Change Password", "Your password was changed successfully " & sName)
		Else
			App.Resume("#form_changepassword")
			App.ToastError("We experienced a problem whilst processing your request, please try again later!")
		End If
	Else
		App.Resume("#form_changepassword")
		App.ToastError("We experienced a problem whilst processing your request, please try again later!")
	End If
End Sub

Sub DeleteUser(sEmail As String)
	mysql.Initialize
	Dim sqldata As String = mysql.DeleteWhere("users", CreateMap("email":sEmail))
	Dim res As String = BANano.CallInlinePHPWait("BANanoMySQL",CreateMap("data":sqldata))
	'get affected records
	Dim resp As Map = App.json2map(res)
	Dim strresp As String = resp.Get("response")
	Dim affectedRows As Int = resp.Get("data")
	If strresp = "OK" And affectedRows = 1 Then
		App.SweetModalSuccess("Account De-Activated", "Your account was de-activated successfully!")
	Else
		App.ToastError("We experienced a problem whilst processing your request, please try again later!")
	End If
End Sub

Sub ResetPassword As UOENowContainer
	Dim rp As UOENowContainer
	rp.Initialize(App,"rp",False,"","","")
	Dim frm As UOENowForm
	frm.Initialize(App,"form_resetpassword","")
	frm.Form.AddRows(5).AddColumns12
	frm.Form.AddParagraph(1,1,"","Please enter the email address that you used to register.","","",True)
	frm.Form.AddEmail(2,1,"rp_email","","Email Address","fas fa-envelope","","","","","",False)
	frm.Form.AddCheckBox1(3,1,"rp_notrobot","I'm not a robot","notrobot","","","",False,False,False,CreateMap("padding-top":"10px","padding-bottom":"10px"))
	frm.Form.AddHorizontalRule(4,1)
	Dim btnReset As UOENowButton
	btnReset.Initialize(App,"btnReset","Reset Password","","","",App.EnumThemes.Primary,"","")
	btnReset.FullWidth = True
	btnReset.IsOutline = True
	btnReset.IsPill = True
	frm.Form.AddButton(5,1,btnReset)
	rp.AddForm(0,0,frm)
	Return rp
End Sub

Sub btnReset_click(e As BANanoEvent)
	'read the form contents
	Dim data As Map = App.form2map("form_resetpassword")
	'everything is compulsory
	Dim bRequired As Boolean = App.RequiredMap(data)
	If bRequired Then
		'we have missing fields, inform user
		App.ToastError("The email is necessary for us to be able to reset you your login credentials. Also confirm you are not a robot!")
		Return
	End If
	'get the email address
	App.PreloaderShow("#form_resetpassword","","","")
	Dim semail As String = data.Get("rp_email")
	'get the first name from db using email address
	mysql.Initialize
	Dim sqldata As String = mysql.SelectWhere("users", Array("firstname"), CreateMap("email":semail), Array("id"))
	Dim res As String = BANano.CallInlinePHPWait("BANanoMySQL",CreateMap("data":sqldata))
	'get the response from MySQL
	Dim resp As Map = App.json2map(res)
	Dim strresp As String = resp.Get("response")
	Dim recs As List = resp.Get("data")
	'if the response is ok, hide the form
	If strresp = "OK" Then
		If recs.Size = 0 Then
			'the email wasnt found, the notification is enough
		Else
			'the email address exists
			Dim userData As Map = recs.Get(0)
			Dim fName As String = userData.Get("firstname")
			'create a new password, save it and then send the email
			Dim snewpwd As String = App.GenerateRandomPassword(8,True,True,True,False)
			'update the database record with the new password
			Dim nrec As Map = CreateMap("password":snewpwd)
			' generate sql json detail
			mysql.Initialize
			Dim sqldata As String = mysql.UpdateWhere("users", nrec, CreateMap("email":semail))
			Dim res As String = BANano.CallInlinePHPWait("BANanoMySQL",CreateMap("data":sqldata))
			'get affected records
			Dim resp As Map = App.json2map(res)
			Dim strresp As String = resp.Get("response")
			Dim affectedRows As Int = resp.Get("data")
			If strresp = "OK" And affectedRows = 1 Then
				'send the new password via email
				Dim nmsg As String = $"Good day ${fName}\r\n\r\nSomeone or you requested the login password to be reset using your email address.\r\n\r\nHere is the new password for your account: ${snewpwd}\r\n\r\nRemember to keep your password safe and do not share it with anyone.\r\n\r\nKind Regards\r\n\r\nAmitek Business College"$
				Dim se As Map = CreateMap("from":App.EmailFrom, "to":semail, "cc":App.EmailCC, "subject":"Amitek Business College Website: " & fName, "msg":nmsg)
				Dim res As String = BANano.CallInlinePHPWait("SendEmail", se)
				Dim resm As Map = App.Json2Map(res)
				Dim response As String = resm.Get("response")
				Select Case response
					Case "failure"
						'App.SweetModalError("Email", $"We experienced a problem sending the email out to ${semail}, please try again later!"$)
					Case Else
						'App.SweetModalSuccess("Email", $"The email was sent successfully for email ${semail}!"$)
				End Select
			End If
		End If
		App.PreloaderHide("#form_resetpassword")
		BANano.CallSub(pgindex,"HideSignIn",Null)
		App.SweetModalWarning("Credentials", "If the email you entered exists in our records, a new password will be emailed!")
	Else
		App.PreloaderHide("#form_resetpassword")
		App.ToastError("We experienced an error whilst processing your request, please try again later!")
	End If
End Sub

Sub ForgotPassword As UOENowContainer
	Dim fp As UOENowContainer
	fp.Initialize(App,"fp",False,"","","")
	Dim frm As UOENowForm
	frm.Initialize(App,"form_forgotpassword","")
	frm.Form.AddRows(4).AddColumns12
	frm.Form.AddParagraph(1,1,"","Please enter the email address that you used to register.","","",True)
	frm.Form.AddEmail(2,1,"fp_email","","Email Address","fas fa-envelope","","","","","",False)
	frm.Form.AddCheckBox1(3,1,"fp_notrobot","I'm not a robot","notrobot","","","",False,False,False,CreateMap("padding-top":"10px","padding-bottom":"10px"))
	frm.Form.AddHorizontalRule(3,1)
	Dim btnForgot As UOENowButton
	btnForgot.Initialize(App,"btnForgot","Forgot Password","","","",App.EnumThemes.Primary,"","")
	btnForgot.FullWidth = True
	btnForgot.IsOutline = True
	btnForgot.IsPill = True
	frm.Form.AddButton(4,1,btnForgot)
	fp.AddForm(0,0,frm)
	Return fp
End Sub

' a user has forgotten his/her email, send via email
Sub btnForgot_click(e As BANanoEvent)
	Dim data As Map = App.form2map("form_forgotpassword")
	Dim bRequired As Boolean = App.RequiredMap(data)
	If bRequired Then
		'we have missing fields, inform user
		App.ToastError("The email is necessary for us to be able to send you your login credentials. Also confirm you are not a robot!")
		Return
	End If
	App.PreloaderShow("#form_forgotpassword","","","")
	Dim semail As String = data.Get("fp_email")
	mysql.Initialize
	Dim sqldata As String = mysql.SelectWhere("users", Array("password", "firstname"), CreateMap("email":semail), Array("id"))
	Dim res As String = BANano.CallInlinePHPWait("BANanoMySQL",CreateMap("data":sqldata))
	Dim resp As Map = App.json2map(res)
	Dim strresp As String = resp.Get("response")
	Dim recs As List = resp.Get("data")
	If strresp = "OK" Then
		If recs.Size = 0 Then
		Else
			'get the only record available
			Dim ufound As Map = recs.Get(0)
			Dim spassword As String = ufound.Get("password")
			Dim fName As String = ufound.Get("firstname")
			Dim nmsg As String = $"Good day ${fName}\r\n\r\nSomeone or you requested the login details using your email address.\r\n\r\nHere is the password for your account: ${spassword}\r\n\r\nRemember to keep your password safe and do not share it with anyone.\r\n\r\nKind Regards\r\n\r\nAmitek Business College"$
			Dim se As Map = CreateMap("from":App.EmailFrom, "to":semail, "cc":App.EmailCC, "subject":"BANAnoMySQL Demo Credentials: " & fName, "msg":nmsg)
			Dim res As String = BANano.CallInlinePHPWait("SendEmail", se)
			Dim resm As Map = App.Json2Map(res)
			Dim response As String = resm.Get("response")
			Select Case response
				Case "failure"
					'App.SweetModalError("Email", $"We experienced a problem sending the email out to ${semail}, please try again later!"$)
				Case Else
					'App.SweetModalSuccess("Email", $"The email was sent successfully for email ${semail}!"$)
			End Select
		End If
		App.PreloaderHide("#form_forgotpassword")
		BANano.CallSub(pgindex,"HideSignIn",Null)
		App.SweetModalWarning("Credentials", "If the email you entered exists in our records, the email with the password will be sent!")
	Else
		App.PreloaderHide("#form_forgotpassword")
		App.ToastError("We experienced an error whilst processing your request, please try again later!")
	End If
End Sub


Sub LoginContainer As UOENowContainer
	Dim lgn As UOENowContainer
	lgn.Initialize(App,"registerc",False,"","","")
	Dim frm As UOENowForm
	frm.Initialize(App,"form_login","")
	frm.Form.AddRows(5).AddColumns12
	frm.Form.AddParagraph(1,1,"","Please enter the email address and password that you used to register.","","",True)
	frm.Form.AddEmail(2,1,"login_email","","Email Address","fas fa-envelope","","","","","",False)
	frm.Form.AddPassword(3,1,"login_password", "", "Password","fas fa-lock-open","","","","","",False)
	frm.Form.AddCheckBox1(4,1,"login_notrobot","I'm not a robot","Y","","","",False,False,False,CreateMap("padding-top":"10px","padding-bottom":"10px"))
	frm.Form.AddHorizontalRule(4,1)
	Dim btnLogin As UOENowButton
	btnLogin.Initialize(App,"btnLogin","Login","","","",App.EnumThemes.Primary,"","")
	btnLogin.FullWidth = True
	btnLogin.IsOutline = True
	btnLogin.IsPill = True
	frm.Form.AddButton(5,1,btnLogin)
	lgn.AddForm(0,0,frm)
	Return lgn
End Sub

Sub btnLogin_click(e As BANanoEvent)
	'get the form data
	Dim data As Map = App.Form2Map("form_login")
	Dim bRequired As Boolean = App.RequiredMap(data)
	If bRequired Then
		'we have missing fields, inform user
		App.ToastError("Both the email and password are required, please enter the correct contents and confirm that you are not a robot!")
		Return
	End If
	'lets remove the prefixes
	Dim udata As Map = App.MapRemovePrefix(data, "login_")
	Dim semail As String = udata.Get("email")
	Dim spassword As String = udata.Get("password")
	mysql.Initialize
	App.Pause("#form_login")
	Dim sqldata As String = mysql.SelectWhere("users", Array("*"), CreateMap("email":semail,"password":spassword), Array("id"))
	Dim res As String = BANano.CallInlinePHPWait("BANanoMySQL",CreateMap("data":sqldata))
	Dim resp As Map = App.json2map(res)
	Dim strresp As String = resp.Get("response")
	Dim recs As List = resp.Get("data")
	If strresp = "OK" Then
		If recs.Size = 0 Then
			' not found
			App.resume("#form_login")
			App.ToastError("The login credentials you have provided could not be verified, please ensure you use a correct email address and password!")
			Return
		Else
			' found
			App.Resume("#form_login")
			BANano.CallSub(pgindex,"HideSignIn",Null)
			Dim userRec As Map = recs.Get(0)
			fName = userRec.Get("firstname")
			BANano.SetSessionStorage("profile", userRec)
			'applied for
			App.SweetModalSuccess("Login",$"Welcome back ${fName}, you can now continue using our portal!"$)
		End If
	Else
		App.Resume("#form_login")
		App.ToastError("We experienced an error whilst processing your login request, please try again later!")
		Return
	End If
End Sub


Sub RegisterContainer() As UOENowContainer
	Dim rc As UOENowContainer
	rc.Initialize(App,"registerc",False,"","","")
	Dim frm As UOENowForm
	frm.Initialize(App,"form_register","")
	frm.Form.AddRows(13).AddColumns12
	frm.Form.AddParagraph(1,1,"","Please enter all the information required here so that we can create a profile for you.","","",True)
	frm.Form.AddTel(2,1,"reg_ssn","","Identity #","fas fa-id-badge","","","","","",False)
	frm.Form.AddTextBox(3,1,"reg_firstname","","First Name","fas fa-user-circle","","","","","",False)
	frm.Form.AddTextBox(4,1,"reg_lastname","","Last Name","fas fa-user-circle","","","","","",False)
	frm.Form.AddEmail(5,1,"reg_email","","Email Address","fas fa-envelope","","","","","",False)
	frm.Form.AddTel(6,1,"reg_telephone","","Cellphone #","fas fa-mobile","","","","","",False)
	frm.Form.AddPassword(9,1,"reg_password", "","Password","fas fa-lock-open","","","","","",False)
	frm.Form.AddPassword(10,1,"reg_confirmpassword","", "Confirm Password","fas fa-lock-open","","","","","",False)
	'frm.Form.AddRadioGroup1(11,1,"reg_applyfor","reg_applyfor","Apply For","COLLEGE",True,"",CreateMap("HIGHSCHOOL":"High School","COLLEGE":"College"),"","",CreateMap("padding-top":"5px"))
	frm.Form.AddCheckBox1(12,1,"reg_confirm","I agree with the Privacy Policy & Terms of Use","confirm","","","",False,False,False,CreateMap("padding-bottom":"15px"))
	frm.Form.AddHorizontalRule(13,1)
	Dim btnRegister As UOENowButton
	btnRegister.Initialize(App,"btnRegister","Register","","","",App.EnumThemes.Primary,"","")
	btnRegister.FullWidth = True
	btnRegister.IsOutline = True
	btnRegister.IsPill = True
	frm.Form.AddButton(13,1,btnRegister)
	rc.AddForm(0,0,frm)
	Return rc
End Sub

'registration process
Sub btnRegister_click(e As BANanoEvent)
	'check if we have all we need
	Dim data As Map = App.Form2Map("form_register")
	Dim bRequired As Boolean = App.RequiredMap(data)
	If bRequired Then
		'we have missing fields, inform user
		App.ToastError("Everything needs to be specified here to be able to continue registering!")
		Return
	End If
	data = App.MapRemovePrefix(data,"reg_")
	'check passwords
	Dim pwd As String = data.Get("password")
	Dim cpwd As String = data.Get("confirmpassword")
	If pwd <> cpwd Then
		App.MarkInValid("reg_password")
		App.MarkInValid("reg_confirmpassword")
		App.ToastError("The specified passwords do not match, please correct them!")
		Return
	End If
	' lets check if this id exists on the server
	'read the email from registration data
	Dim remail As String = data.Get("email")
	Dim rssn As String = data.Get("ssn")
	Dim stelephone As String = data.Get("telephone")
	Dim fName As String = data.Get("firstname")
	'if any record exist, user is registered
	Dim iFound As Int = 0
	'****WE WILL CHECK ALL 3 TO ENSURE NO RECORDS ARE DUPLICATED
	'build the query to find email address
	mysql.Initialize
	App.Pause("#form_register")
	Dim sqldata As String = mysql.SelectWhere("users", Array As String("id"), CreateMap("email":remail), Array("id"))
	Dim emailResult As String = BANano.CallInlinePHPWait("BANanoMySQL",CreateMap("data":sqldata))
	Dim resp As Map = App.json2map(emailResult)
	Dim strresp As String = resp.Get("response")
	Dim recs As List = resp.Get("data")
	If strresp = "OK" Then
		If recs.Size = 0 Then
			App.MarkValid("reg_email")
		Else
			App.MarkInValid("reg_email")
		End If
		iFound = iFound + recs.Size
	Else
		App.Resume("#form_register")
		App.ToastError("We experienced an error whilst processing your request, please try again later!")
		Return
	End If
	'SSN
	mysql.Initialize
	sqldata = mysql.SelectWhere("users", Array As String("id"), CreateMap("ssn":rssn), Array("id"))
	Dim ssnResult As String = BANano.CallInlinePHPWait("BANanoMySQL",CreateMap("data":sqldata))
	Dim resp As Map = App.json2map(ssnResult)
	Dim strresp As String = resp.Get("response")
	Dim recs As List = resp.Get("data")
	If strresp = "OK" Then
		If recs.Size = 0 Then
			App.MarkValid("reg_ssn")
		Else
			App.MarkInValid("reg_ssn")
		End If
		iFound = iFound + recs.Size
	Else
		App.resume("#form_register")
		App.ToastError("We experienced an error whilst processing your request, please try again later!")
		Return
	End If
	'TELEPHONE
	mysql.Initialize
	sqldata = mysql.SelectWhere("users", Array As String("id"), CreateMap("telephone":stelephone), Array("id"))
	Dim telResult As String = BANano.CallInlinePHPWait("BANanoMySQL",CreateMap("data":sqldata))
	Dim resp As Map = App.json2map(telResult)
	Dim strresp As String = resp.Get("response")
	Dim recs As List = resp.Get("data")
	If strresp = "OK" Then
		If recs.Size = 0 Then
			App.MarkValid("reg_telephone")
		Else
			App.MarkInValid("reg_telephone")
		End If
		iFound = iFound + recs.Size
	Else
		App.resume("#form_register")
		App.ToastError("We experienced an error whilst processing your request, please try again later!")
		Return
	End If
	If iFound <> 0 Then
		App.Resume("#form_register")
		App.ToastError("Either the identity #, email address, cellphone # is already taken in our records, the registration cannot be completed!")
		Return
	End If
	'process the registration, remove thr primary key
	data.Remove("id")
	data.remove("confirmpassword")
	data.remove("confirm")
	mysql.Initialize
	Dim sqldata As String = mysql.Insert("users",data)
	Dim regResult As String = BANano.CallInlinePHPWait("BANanoMySQL",CreateMap("data":sqldata))
	Dim resp As Map = App.json2map(regResult)
	Dim strresp As String = resp.Get("response")
	If strresp = "OK" Then
		'create the profile for the student
		App.resume("#form_register")
		BANano.CallSub(pgindex,"HideSignIn", Null)
		App.SweetModalSuccess("Registration",$"Welcome to the BANanoMySQL family ${fName}. You can now Log into the Online Portal using your email and password!"$)
		Dim reg As Map = App.Form2Map("form_register")
		'clear all input controls per form
		App.ClearValuesMap(reg)
		'ready
		'set us on the login tab
		App.ShowTab("login")
	Else
		App.resume("#form_register")
		App.ToastError("We experienced an error whilst processing your registration, please try again later!")
	End If
End Sub