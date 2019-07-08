B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=7.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Public signin As UOENowModal
	Private App As UOENowApp
	Private BANano As BANano
	Public Page As UOENowPage
	Private easyHint As UOEEasyHint
End Sub

Sub Init(thisApp As UOENowApp)
	App = thisApp
	easyHint.Initialize
	'initialized the page, the 'main' div name will be components
	Page.Initialize(App,"index",False,True,App.EnumThemes.primary)
	'Page.NavBar.AddImage("logo","./assets/logo.png","",False,False,False,"","",False)
	Page.NavBar.AddHamBurger
	Page.NavBar.RemoveBottomMargin
	Page.NavBar.ProperCaseNavItems
	Page.NavBar.JustifyContentEnd
	Page.NavBar.AddBrand("logo","BANanoMySQL Demo","#")
	easyHint.AddStep("logo","Welcome to BANanoMySQL Demo<br>Here we will explore CRUD functionality<br>for MySQL inline PHP<br>First we need to create a MySQL DB.")
	'Page.NavBar.SetFixed
	Page.NavBar.AddAnchor("createdb","{NBSP}Database", "#",App.EnumNucleo.location_pin,"",False,False,"",False)
	easyHint.AddStep("createdb","Select this option to create a MySQL DB<br>This will be based on your connection settings.")
	Page.NavBar.AddAnchor("login","{NBSP}Login", "#",App.EnumNucleo.location_pin,"",False,False,"",False)
	easyHint.AddStep("login","After you have created the DB, select Login to register and login.")
	easyHint.EndsOn("login")
	' 
	Page.Header.Visible = True
	'	
	signin = pgSignIn.SignIn(App)
	Page.Content.AddModal(signin)
	'
	Page.Footer.CopyRight.CopyRight.AddText(", Designed by ")
	Page.Footer.CopyRight.Copyright.AddAnchor1(0,0,"","TGIF Zone Inc","https://www.tgifzone.com",App.EnumTarget.blank,False,"","")
	Page.Footer.CopyRight.CenterOnPage
	Page.Footer.Visible = True
	'
	Page.create
	BANano.GetElement("#body").AddClass("loadhere")
	Page.profilepage
	' bind events
	App.BindClickEvent("createdb",Me)
	App.BindClickEvent("login",Me)
	
	'the modal form is added to this page, lets bind its events here
	App.BindClickEvent("btnLogin",pgSignIn)
	App.BindClickEvent("btnRegister", pgSignIn)
	App.BindClickEvent("btnReset", pgSignIn)
	App.BindClickEvent("btnForgot", pgSignIn)
	App.BindClickEvent("btnChangePassword", pgSignIn)
	'
	easyHint.Run
End Sub

Sub createdb_click(e As BANanoEvent)
	'let's create a mysql database
	'this is not need if a db is existing
	Dim mysql As BANanoMySQL
	mysql.initialize
	'define the sql command to create the table
	Dim sql As String = mysql.CreateDatabase("bananomysqldemo")
	'execute the php call to create the db
	Dim res As String = BANano.CallInlinePHPWait("BANanoMySQL",CreateMap("data":sql))
	'get the response from MySQL, its a json response, convert to map
	Dim resp As Map = App.json2map(res)
	'get the response key
	Dim sresp As String = resp.Get("response")
	If sresp = "OK" Then
		'everything went well
		App.ToastSuccess("Database created successfully!")
	Else
		App.SweetModalError("Database Error", "An issue experienced creating the database!")
		Return
	End If
	
	'let's create the table structure
	Dim usersTB As Map = CreateMap()
	usersTB.Put("id", mysql.DB_INT)
	usersTB.Put("ssn", mysql.DB_VARCHAR_20)
	usersTB.Put("firstname", mysql.DB_VARCHAR_50)
	usersTB.Put("lastname", mysql.DB_VARCHAR_50)
	usersTB.Put("email", mysql.DB_VARCHAR_50)
	usersTB.Put("telephone", mysql.DB_VARCHAR_20)
	usersTB.Put("password", mysql.DB_VARCHAR_20)
	usersTB.Put("applyfor", mysql.DB_VARCHAR_20)
	'build the sql command to create the table
	Dim sql As String = mysql.CreateTable("users", usersTB,"id","id")
	'execute the php call to create the table
	Dim res As String = BANano.CallInlinePHPWait("BANanoMySQL",CreateMap("data":sql))
	'get the response from MySQL, its a json response, convert to map
	Dim resp As Map = App.json2map(res)
	Dim sresp As String = resp.Get("response")
	If sresp = "OK" Then
		'everything went well
		App.ToastSuccess("Users table created successfully!")
	Else
		App.SweetModalError("Users Error", "An issue experienced creating the users table!")
		Return
	End If
End Sub

'hide the modal sheet for registrations
Sub HideSignIn
	signin.hide
End Sub

Sub login_click(e As BANanoEvent)
	'show the modal sheet
	signin.show
	'get the form details for each form
	Dim cp As Map = App.Form2Map("form_changepassword")
	Dim rp As Map = App.Form2Map("form_resetpassword")
	Dim fp As Map = App.Form2Map("form_forgotpassword")
	Dim lng As Map = App.Form2Map("form_login")
	Dim reg As Map = App.Form2Map("form_register")
	'clear all input controls per form
	App.ClearValuesMap(cp)
	App.ClearValuesMap(rp)
	App.ClearValuesMap(fp)
	App.ClearValuesMap(lng)
	App.ClearValuesMap(reg)
	'ready
	App.SetValue("id","-1")
	App.SetRadio("reg_applyfor","COLLEGE")
	'set us on the login tab
	App.ShowTab("login")
End Sub
