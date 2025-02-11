
TYPE
	StepEnum : 
		(
		tpWAIT,
		tpCONNECT,
		tpDISCONNECT,
		tpPATH_GET,
		tpPATH_SAVE,
		tpSUBSCRIPTION,
		tpSUBSCRIPTION_DELETE,
		tpHANDLELIST,
		tpHANDLELIST_RELEASE,
		tpMONITORLIST,
		tpMONITORLIST_REMOVE,
		tpFIRST_READ,
		tpREADY,
		tpWRITE_TRANSLATE,
		tpWRITE_BULK,
		tpWRITE_WAIT,
		tpMETHOD_HANDLE,
		tpMETHOD_CALL,
		tpMETHOD_RELEASE,
		tpERROR,
		tpNONE
		);
	PowerPanelType : 	STRUCT 
		Command : PowerPanelCmdType;
		Data : PowerPanelDataType;
		Parameter : PowerPanelParType;
		Method : MethodType;
		Diag : PowerPanelDiagType;
	END_STRUCT;
	PowerPanelCmdType : 	STRUCT 
		Connect : BOOL;
		Disconnect : BOOL;
		Write : BOOL;
		ResetError : BOOL;
	END_STRUCT;
	PowerPanelDataType : 	STRUCT 
		Startup : StartupType;
		Network : NetworkType;
		Time : TimeType;
		Screen : ScreenType;
		Audio : AudioType;
		Gesture : GestureType;
		Vnc : VncType;
		Web : WebType;
		Storage : StorageType;
		RemoteAccess : RemoteAccessType;
		AboutInfo : AboutInfoType;
		Diagnostics : DiagnosticsType;
		Status : StatusType;
		HandButton : GestureType;
	END_STRUCT;
	PowerPanelParType : 	STRUCT  (*Use one of the following types: T30, T50, FT50, T80*)
		PanelType : STRING[5];
		PanelIP : STRING[15];
	END_STRUCT;
	PowerPanelDiagType : 	STRUCT 
		PingOk : BOOL;
		IsConnected : BOOL;
		PendingWrites : BOOL;
		Step : StepEnum;
		StatusText : STRING[200];
		StatusId : DWORD;
		VariableErrors : ARRAY[0..9]OF STRING[200];
		VariableErrorsIndex : USINT;
		VisHelperConnectVisible : BOOL;
		VisHelperErrorVisible : BOOL;
		ErrorStep : StepEnum := tpNONE;
	END_STRUCT;
	StartupType : 	STRUCT 
		StartMode : UDINT;
		ShowBootLogoVNC : BOOL;
		ShowBootLogoWeb : BOOL;
		USBMemoryShare : BOOL;
		UserMemoryShare : BOOL;
	END_STRUCT;
	NetworkType : 	STRUCT 
		Hostname : STRING[79];
		NetworkMode : UDINT;
		ActivateDNS : BOOL;
		DNSSuffix : STRING[79];
		GetDNSFromDHCP : BOOL;
		PrimaryDNS : STRING[79];
		SecondaryDNS : STRING[79];
		TertiaryDNS : STRING[79];
		IpAddress : STRING[79];
		SubnetMask : STRING[79];
		DefaultGateway : STRING[79];
	END_STRUCT;
	TimeType : 	STRUCT 
		EnableNTPClient : BOOL;
		NTPServer1 : STRING[79];
		CurrentDateTime : DATE_AND_TIME;
	END_STRUCT;
	ScreenType : 	STRUCT 
		DisplayBrightness : USINT;
		ScreenRotation : UDINT;
		EnableScreensaver : BOOL;
		ScreensaverIdleTime : UINT;
		ScreensaverType : UDINT;
		BootAnimationDelay : UINT;
		BootAnimationLeftPos : UINT;
		BootAnimationTopPos : UINT;
	END_STRUCT;
	AudioType : 	STRUCT 
		EnableBuzzer : BOOL;
		BuzzerSource : UDINT;
		BuzzerFrequency : UINT;
		BuzzerDuration : UINT;
	END_STRUCT;
	GestureType : 	STRUCT 
		OpenServicePage : BOOL;
	END_STRUCT;
	DiagnosticsType : 	STRUCT 
		CPUCore0Usage : USINT;
		CPUCore1Usage : USINT;
		CPUUsage : USINT;
		MemoryAvailable : UINT;
		MemoryTotal : UINT;
	END_STRUCT;
	VncType : 	STRUCT 
		VNCServer : STRING[79];
		UseRfbExtension : BOOL;
		VNCLocalWindowScaling : BOOL;
		VNCBackgroundColor : STRING[79];
		VNCConnectionMonitor : BOOL;
	END_STRUCT;
	WebType : 	STRUCT 
		WebServer : STRING[79];
		VirtualKeyboardWeb : BOOL;
		DisablePinchGesture : BOOL;
		SetOverrideViewport : BOOL;
		ViewportSettings : STRING[79];
		IgnoreServerCertificateErrors : BOOL;
		EnableScreenCapture : BOOL;
		SuppressScrnCaptSecWarn : BOOL;
		WaitForNtpSync : BOOL;
	END_STRUCT;
	StorageType : 	STRUCT 
		USBMemoryShare : BOOL;
		UserMemoryShare : BOOL;
	END_STRUCT;
	RemoteAccessType : 	STRUCT 
		EnableRemoteAccess : BOOL;
		RemoteAccessBackEnd : UDINT;
		RemoteAccessModeVNC : UDINT;
		RemoteAccessModeWebGL : UDINT;
		RemoteAccessPortWebGL : UINT;
		RemoteAccessWSPortWebGL : UINT;
		RemoteAccessPortVNC : UINT;
	END_STRUCT;
	AboutInfoType : 	STRUCT 
		CompatibilityId : UDINT;
		DeviceRevision : STRING[79];
		HardwareRevision : STRING[79];
		Manufacturer : STRING[79];
		Model : STRING[79];
		ProductCode : UDINT;
		RevisionCounter : DINT;
		SerialNumber : STRING[79];
		SoftwareRevision : STRING[79];
		VendorId : UDINT;
	END_STRUCT;
	StatusType : 	STRUCT 
		Temperature0 : REAL;
		Temperature1 : REAL;
		USBFlashDrive0 : UDINT;
		USBFlashDrive1 : UDINT;
	END_STRUCT;
	MethodType : 	STRUCT 
		Type : PanelMethodType := NoMethod;
		BuzzerDuration : UDINT := 500;
		BuzzerFrequency : UDINT := 10000;
		ActualTime : STRING[79];
		Brightness : UDINT := 50;
	END_STRUCT;
	PanelMethodType : 
		(
		NoMethod,
		AwakePanel,
		RestartSystem,
		StartRemoteAccess,
		StopRemoteAccess,
		SaveConfiguration,
		LoadConfiguration,
		StartUpdate,
		BuzzerDefault,
		BuzzerWithPara,
		SetBrightness,
		SetBrightnessUnlimited,
		SetTime
		);
	PvType : 	STRUCT 
		ObjectIndex : INT;
		Adr : UDINT;
		AdrShadow : UDINT;
		DataLen : UDINT;
	END_STRUCT;
	BrowseType : 	STRUCT 
		BrowsePath : STRING[79];
		VariableName : STRING[79];
		Argument : STRING[79];
		NamespaceIndex : UINT;
		Identifier : STRING[79];
		Access : STRING[1];
	END_STRUCT;
END_TYPE
