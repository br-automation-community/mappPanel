PROGRAM _INIT
	// Transfer configuration
	PowerPanel.Parameter.PanelIP := PanelIpAddress;
	PowerPanel.Parameter.PanelType := PanelType;
	
	// Get task name
	ST_name(0,ADR(TaskName),0);
	PowerPanel.Data.Diagnostics.MemoryAvailable := 0;
		
	// Get data module details
	fbGetBrowsePath(enable := TRUE, pName := ADR('BrowsePath'));
	IF (fbGetBrowsePath.status = ERR_OK) THEN	
		VariablesTotalIndex := UDINT_TO_INT(fbGetBrowsePath.len/SIZEOF(pBrowseVar));
	ELSE
		PowerPanel.Diag.StatusId := ERR_PANEL_NO_DATA_MODULE;
		PowerPanel.Diag.StatusText := 'no data module found';
		PowerPanel.Diag.Step := tpERROR;
	END_IF
END_PROGRAM

PROGRAM _EXIT
	REPEAT
		fbMonitoredItemRemoveList.Execute := TRUE;
		fbMonitoredItemRemoveList.SubscriptionHdl := fbSubscriptionCreate.SubscriptionHdl;
		fbMonitoredItemRemoveList.MonitoredItemHdlCount := VariablesReadIndex;
		fbMonitoredItemRemoveList.MonitoredItemHdls := fbMonitoredItemAddList.MonitoredItemHdls;
		fbMonitoredItemRemoveList();
		UNTIL NOT fbMonitoredItemRemoveList.Busy
	END_REPEAT
	REPEAT
		fbSubscriptionDelete.Execute := TRUE;
		fbSubscriptionDelete.SubscriptionHdl := fbSubscriptionCreate.SubscriptionHdl;
		fbSubscriptionDelete();
		UNTIL NOT fbSubscriptionDelete.Busy
	END_REPEAT	
	REPEAT
		fbNodeReleaseHandleList.Execute := TRUE;
		fbNodeReleaseHandleList.ConnectionHdl := fbConnect.ConnectionHdl;
		fbNodeReleaseHandleList.NodeHdls := fbNodeGetHandleList.NodeHdls;
		fbNodeReleaseHandleList.NodeHdlCount := VariablesReadIndex;
		fbNodeReleaseHandleList();
		UNTIL NOT fbNodeReleaseHandleList.Busy
	END_REPEAT	
	REPEAT
		fbDisconnect.Execute := TRUE;
		fbDisconnect.ConnectionHdl := fbConnect.ConnectionHdl;
		fbDisconnect();	
		UNTIL NOT fbDisconnect.Busy
	END_REPEAT		
END_PROGRAM