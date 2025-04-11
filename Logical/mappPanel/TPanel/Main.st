
PROGRAM _CYCLIC
	// Make sure panel is reachable
	CheckPing;
	
	// Some helpers for the HMI
	PowerPanel.Diag.VisHelperConnectVisible := NOT PowerPanel.Diag.IsConnected;
	PowerPanel.Diag.VisHelperErrorVisible := PowerPanel.Diag.Step = tpERROR;

	// Some helpers for the OPC UA data
	PowerPanel.Data.AboutInfo.Manufacturer := Manufacturer.Text;
	PowerPanel.Data.AboutInfo.Model := Model.Text;

	// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
	// Panel OPC UA connection state machine
	// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
	CASE PowerPanel.Diag.Step OF
		
		// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		// IDLE state
		// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpWAIT:			
			i := 0;
			PowerPanel.Diag.StatusText := 'Disconnected';
			PowerPanel.Diag.StatusId := 0;

			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Wait for server to get ready
			IF (UaSrv_GetServerState() = UASS_Running) AND (PowerPanel.Diag.PingOk) AND (VariablesTotalIndex > 0) THEN
				
				// Wait for connect command
				IF PowerPanel.Command.Connect THEN
					// Make sure we have a valid IP address
					IF PowerPanel.Parameter.PanelIP = '' THEN
						PowerPanel.Diag.StatusId := ERR_PANEL_IP_EMPTY;
						PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
						PowerPanel.Diag.StatusText := 'IP address is empty';
						PowerPanel.Diag.Step := tpERROR;
						RETURN;
					END_IF

					// Make sure we have a valid panel type
					IF PowerPanel.Parameter.PanelType = '' THEN
						PowerPanel.Diag.StatusId := ERR_PANEL_PANEL_TYPE_EMPTY;
						PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
						PowerPanel.Diag.StatusText := 'Panel type is empty. Use one of the following types: T30, T50, FT50, T80';
						PowerPanel.Diag.Step := tpERROR;
						RETURN;
					END_IF

					brsmemset(ADR(UANodeIDMonitor), 0, SIZEOF(UANodeIDMonitor));					
					brsmemset(ADR(fbTranslatePath), 0, SIZEOF(fbTranslatePath));					
					brsmemset(ADR(fbSubscriptionCreate), 0, SIZEOF(fbSubscriptionCreate));					
					brsmemset(ADR(fbMonitoredItemAddList), 0, SIZEOF(fbMonitoredItemAddList));					
					brsmemset(ADR(fbNodeGetHandleList), 0, SIZEOF(fbNodeGetHandleList));
					brsmemset(ADR(PowerPanel.Diag.VariableErrors), 0, SIZEOF(PowerPanel.Diag.VariableErrors));
					PowerPanel.Diag.VariableErrorsIndex := 0;
					PowerPanel.Method.Type := NoMethod;
					
					// Prepare read variables
					brsmemset(ADR(MonitoringParameters), 0, SIZEOF(MonitoringParameters));
					FOR i := 0 TO INDEX_LIST DO	
						MonitoringParameters[i].SamplingInterval := PublishingInterval;
						MonitoringParameters[i].Deadband := 0;
						MonitoringParameters[i].DeadbandType := UADeadbandType_None;
						MonitoringParameters[i].QueueSize := 0;
					END_FOR
					
					PowerPanel.Diag.StatusId := UINT_TO_DWORD(ERR_FUB_BUSY);
					PowerPanel.Diag.Step := tpCONNECT;
				END_IF				
			END_IF
		
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Connect to panel via OPC
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpCONNECT:
			PowerPanel.Diag.StatusText := 'Connecting to panel...';

			// Set parameters for function call
			fbConnect.Execute := TRUE;
			fbConnect.ServerEndpointUrl := 'opc.tcp://';
			fbConnect.ServerEndpointUrl := CONCAT(fbConnect.ServerEndpointUrl, PowerPanel.Parameter.PanelIP);
			fbConnect.ServerEndpointUrl := CONCAT(fbConnect.ServerEndpointUrl, ':4840');
			fbConnect.Timeout := T#10s;

			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Success
			IF fbConnect.Done THEN
				// Reset function block
				fbConnect.Execute := FALSE;
				
				// Set device and version string
				Device := '/0:Objects/2:DeviceSet/4:PowerPanel';
				Device := CONCAT(Device, PowerPanel.Parameter.PanelType);
				
				// Prepare path translation
				i := 0;
				Offset := 0;
				pBrowseVar ACCESS (fbGetBrowsePath.pDatObjMem + Offset);
				BrowseVar := pBrowseVar;
				brsmemset(ADR(fbTranslatePath.RelativePath), 0, SIZEOF(fbTranslatePath.RelativePath));
				
				PowerPanel.Diag.Step := tpPATH_GET;

				// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
				// Go to error state
			ELSIF fbConnect.Error THEN
				fbConnect.Execute := FALSE;
				PowerPanel.Diag.StatusId := fbConnect.ErrorID;
				PowerPanel.Diag.StatusText := 'Error connecting to panel. ';				
				IF PowerPanel.Diag.StatusId = 16#8005_0000 THEN
					brsstrcat(ADR(PowerPanel.Diag.StatusText), ADR('Make sure OPC UA server is activated.'));				
				END_IF
				PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
				PowerPanel.Diag.Step := tpERROR;
			END_IF

			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Function call
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Get path details
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpPATH_GET:
			PowerPanel.Diag.StatusText := 'Translating path...';

			// Set parameters for function call
			fbTranslatePath.Execute := TRUE;
			fbTranslatePath.ConnectionHdl := fbConnect.ConnectionHdl;
			fbTranslatePath.RelativePath := pBrowseVar.BrowsePath;
			fbTranslatePath.StartNodeID.Identifier := '84';
			fbTranslatePath.StartNodeID.IdentifierType := UAIdentifierType_Numeric;
			fbTranslatePath.Timeout := T#10s;

			IF (pBrowseVar.Access <> 'S') THEN
				fbTranslatePath.RelativePath := INSERT(fbTranslatePath.RelativePath, Device, 0);
			END_IF

			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Success
			IF fbTranslatePath.Done THEN
				BrowseVar.NamespaceIndex := fbTranslatePath.TargetNodeID.NamespaceIndex;
				BrowseVar.Identifier := fbTranslatePath.TargetNodeID.Identifier;
				brsmemset(ADR(fbTranslatePath), 0, SIZEOF(fbTranslatePath));					
				PowerPanel.Diag.Step := tpPATH_SAVE;

				// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
				// Go to error state
			ELSIF fbTranslatePath.Error THEN
				fbTranslatePath.Execute := FALSE;
				// Variable is not available on this target
				IF (fbTranslatePath.ErrorID = 16#806F0000) OR (fbTranslatePath.ErrorID = 16#80AB0000) THEN
					PowerPanel.Diag.VariableErrors[PowerPanel.Diag.VariableErrorsIndex] := pBrowseVar.BrowsePath;
					IF PowerPanel.Diag.VariableErrorsIndex < SIZEOF(PowerPanel.Diag.VariableErrors)/SIZEOF(PowerPanel.Diag.VariableErrors[0]) - 1 THEN
						PowerPanel.Diag.VariableErrorsIndex := PowerPanel.Diag.VariableErrorsIndex + 1;
					END_IF
					PowerPanel.Diag.Step := tpPATH_SAVE;
				ELSE
					PowerPanel.Diag.StatusId := fbTranslatePath.ErrorID;
					PowerPanel.Diag.StatusText := 'Error translating path information';
					PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
					PowerPanel.Diag.Step := tpERROR;
				END_IF
			END_IF			
		
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Save path information in data module
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpPATH_SAVE: 
			PowerPanel.Diag.StatusText := 'Saving path...';

			// Set parameters for function call
			fbWritePath.enable := TRUE;
			fbWritePath.ident := fbGetBrowsePath.ident;
			fbWritePath.Offset := Offset;
			fbWritePath.pSource := ADR(BrowseVar);
			fbWritePath.len := SIZEOF(BrowseVar);
			fbWritePath();

			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Success
			IF (fbWritePath.status = ERR_OK) THEN
				i := i + 1;
				
				// Translate path for next variable
				IF i < VariablesTotalIndex THEN
					Offset := i * SIZEOF(pBrowseVar);
					pBrowseVar ACCESS (fbGetBrowsePath.pDatObjMem + Offset);
					BrowseVar := pBrowseVar;					
					brsmemset(ADR(fbTranslatePath.RelativePath), 0, SIZEOF(fbTranslatePath.RelativePath));
					PowerPanel.Diag.Step := tpPATH_GET;
					// Go to subscibe
				ELSE
					fbWritePath.enable := FALSE;

					DefineVariablesRead;
					DefineVariablesWrite;
					PowerPanel.Diag.Step := tpSUBSCRIPTION;
				END_IF

				// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
				// Go to error state
			ELSIF (fbWritePath.status <> ERR_FUB_BUSY) THEN
				PowerPanel.Diag.StatusId := UINT_TO_DWORD(fbWritePath.status);
				PowerPanel.Diag.StatusText := 'Error saving path information';
				PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
				PowerPanel.Diag.Step := tpERROR;				
			END_IF		
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Start subsciption
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpSUBSCRIPTION:
			PowerPanel.Diag.StatusText := 'Subscribing...';

			// Set parameters for function call
			fbSubscriptionCreate.Execute := TRUE;
			fbSubscriptionCreate.ConnectionHdl := fbConnect.ConnectionHdl;
			fbSubscriptionCreate.Priority := 0;
			fbSubscriptionCreate.PublishingEnable := TRUE;
			fbSubscriptionCreate.Timeout := T#10s;

			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Success
			IF fbSubscriptionCreate.Done THEN
				fbSubscriptionCreate.Execute := FALSE;
				PowerPanel.Diag.Step := tpHANDLELIST;

				// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
				// Go to error state
			ELSIF fbSubscriptionCreate.Error THEN
				fbSubscriptionCreate.Execute := FALSE;
				PowerPanel.Diag.StatusId := fbSubscriptionCreate.ErrorID;
				PowerPanel.Diag.StatusText := 'Error subscribing to data';
				PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
				PowerPanel.Diag.Step := tpERROR;
			END_IF
	
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Get handles
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpHANDLELIST:
			PowerPanel.Diag.StatusText := 'Get handle list...';

			// Set parameters for function call
			fbNodeGetHandleList.Execute := TRUE;
			fbNodeGetHandleList.ConnectionHdl := fbConnect.ConnectionHdl;
			fbNodeGetHandleList.NodeIDs := UANodeIDMonitor;
			fbNodeGetHandleList.NodeIDCount := VariablesReadIndex;
			fbNodeGetHandleList.Timeout := T#10s;

			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Success
			IF fbNodeGetHandleList.Done THEN
				fbNodeGetHandleList.Execute := FALSE;
				PowerPanel.Diag.Step := tpMONITORLIST;

				// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
				// Go to error state
			ELSIF fbNodeGetHandleList.Error THEN
				fbNodeGetHandleList.Execute := FALSE;
				PowerPanel.Diag.StatusId := fbNodeGetHandleList.ErrorID;
				PowerPanel.Diag.StatusText := 'Error getting handle list. ';
				IF PowerPanel.Diag.StatusId = 16#800F_0000 THEN
					brsstrcat(ADR(PowerPanel.Diag.StatusText), ADR('Make sure panel type was set correct.'));
				END_IF

				// Find broken variable
				FOR i := 0 TO VariablesReadIndex DO
					IF fbMonitoredItemAddList.NodeErrorIDs[i] <> 0 THEN
						PowerPanel.Diag.StatusId := fbMonitoredItemAddList.NodeErrorIDs[i];
						PowerPanel.Diag.StatusText := VariablesReadInfo[i];
					END_IF
				END_FOR
				
				PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
				PowerPanel.Diag.Step := tpERROR;
			END_IF
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Start monitoring items
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpMONITORLIST:
			PowerPanel.Diag.StatusText := 'Start monitoring...';

			// Set parameters for function call
			fbMonitoredItemAddList.Execute := TRUE;
			fbMonitoredItemAddList.SubscriptionHdl := fbSubscriptionCreate.SubscriptionHdl;
			fbMonitoredItemAddList.NodeHdlCount := VariablesReadIndex;
			fbMonitoredItemAddList.NodeHdls := fbNodeGetHandleList.NodeHdls;
			fbMonitoredItemAddList.NodeAddInfos := NodeAddInfoMonitor;
			fbMonitoredItemAddList.Timeout := T#10s;

			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Success
			IF fbMonitoredItemAddList.Done THEN			
				fbMonitoredItemAddList.Execute := FALSE;
				
				// Reset first read timer
				fbFirstReadTimeout.IN := 0;
				fbFirstReadTimeout();

				PowerPanel.Diag.Step := tpFIRST_READ;

				// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
				// Go to error state
			ELSIF fbMonitoredItemAddList.Error THEN
				fbMonitoredItemAddList.Execute := FALSE;
				PowerPanel.Diag.StatusId := fbMonitoredItemAddList.ErrorID;
				PowerPanel.Diag.StatusText := 'Error monitoring to data';
				
				// Find broken variable
				FOR i := 0 TO VariablesReadIndex DO
					IF fbMonitoredItemAddList.NodeErrorIDs[i] <> 0 THEN
						PowerPanel.Diag.StatusId := fbMonitoredItemAddList.NodeErrorIDs[i];
						PowerPanel.Diag.StatusText := VariablesReadInfo[i];
					END_IF
				END_FOR
				
				PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
				PowerPanel.Diag.Step := tpERROR;
			END_IF
		
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Wait for first data to arrive
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpFIRST_READ:
			PowerPanel.Diag.StatusText := 'Wait for first data...';

			fbFirstReadTimeout.IN := 1;
			fbFirstReadTimeout();
			
			// Panel did not respond with first data after 10s
			IF fbFirstReadTimeout.Q THEN
				PowerPanel.Diag.StatusId := ERR_PANEL_FIRST_READ;
				PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
				PowerPanel.Diag.StatusText := 'First read timed out';
				PowerPanel.Diag.Step := tpERROR;
			END_IF
			
			// Wait for first values to arrive
			IF PowerPanel.Data.AboutInfo.SerialNumber <> '' THEN
				// Create variable shadow for write variables
				FOR i := 0 TO VariablesWriteIndex - 1 DO
					brsmemcpy(VariablesWriteInfo[i].AdrShadow, VariablesWriteInfo[i].Adr, VariablesWriteInfo[i].DataLen);
				END_FOR
				
				PowerPanel.Diag.Step := tpREADY;
			END_IF
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Ready state with cyclic data exchange
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpREADY:
			// Set status and reset commands
			PowerPanel.Diag.StatusText := 'Ready';
			PowerPanel.Command.Connect := FALSE;
			PowerPanel.Command.ResetError := FALSE;
			PowerPanel.Diag.StatusId := 0;
			PowerPanel.Diag.IsConnected := TRUE;
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Track value changes
			CheckValueChange;
			IF VariablesChangeIndex > 0 AND PowerPanel.Command.Write THEN
				PowerPanel.Diag.StatusText := 'Writing new settings...';
				PowerPanel.Diag.Step := tpWRITE_BULK;
				RETURN;
			END_IF
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Method call handling
			IF PowerPanel.Method.Type <> NoMethod THEN
				PowerPanel.Diag.StatusText := 'Executing method...';
				DefineMethod;
				PowerPanel.Diag.StatusId := UINT_TO_DWORD(ERR_FUB_BUSY);
				PowerPanel.Diag.Step := tpMETHOD_HANDLE;
			END_IF
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Command disconnect 
			IF PowerPanel.Command.Disconnect THEN
				PowerPanel.Diag.StatusText := 'Disconneting...';
				PowerPanel.Diag.StatusId := UINT_TO_DWORD(ERR_FUB_BUSY);
				PowerPanel.Diag.Step := tpMONITORLIST_REMOVE;
			END_IF
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Write all data that was changed
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpWRITE_BULK:
			// Set parameters for function call
			fbWriteBulk.Execute := TRUE;
			fbWriteBulk.ConnectionHdl := fbConnect.ConnectionHdl;
			fbWriteBulk.NodeIDCount := VariablesChangeIndex;
			fbWriteBulk.NodeIDs := ADR(UANodeIDWrite);
			fbWriteBulk.NodeAddInfo := ADR(NodeAddInfoWrite);
			fbWriteBulk.NodeErrorIDs := ADR(NodeErrorIdWrite);
			fbWriteBulk.Variables := ADR(VariablesChanged);

			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Success
			IF fbWriteBulk.Done THEN
				fbWriteBulk.Execute := FALSE;
				PowerPanel.Diag.Step := tpWRITE_WAIT;
				
				// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
				// Go to error state
			ELSIF fbWriteBulk.Error THEN
				fbWriteBulk.Execute := FALSE;
				PowerPanel.Diag.StatusId := fbWriteBulk.ErrorID;
				PowerPanel.Diag.StatusText := 'Error writing data';
				
				// Find broken variable
				FOR i := 0 TO VariablesChangeIndex DO
					IF NodeErrorIdWrite[i] <> 0 THEN
						PowerPanel.Diag.StatusId := NodeErrorIdWrite[i];
					END_IF
				END_FOR
				
				PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
				PowerPanel.Diag.Step := tpERROR;
			END_IF
		
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Wait for data to sink in
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpWRITE_WAIT:
			fbWaitAfterWrite.IN := TRUE;
			fbWaitAfterWrite();

			IF fbWaitAfterWrite.Q THEN
				fbWaitAfterWrite.IN := FALSE;
				fbWaitAfterWrite();
				
				// Create variable shadow for write variables
				FOR i := 0 TO VariablesWriteIndex - 1 DO
					brsmemcpy(VariablesWriteInfo[i].AdrShadow, VariablesWriteInfo[i].Adr, VariablesWriteInfo[i].DataLen);
				END_FOR
				
				// Reset command and flag
				PowerPanel.Command.Write := FALSE;
				PowerPanel.Diag.PendingWrites := FALSE;

				PowerPanel.Diag.Step := tpREADY;
			END_IF

			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Get method handle
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpMETHOD_HANDLE:	
			// Set parameters for function call
			fbMethodGetHandle.Execute := TRUE;
			fbMethodGetHandle.ConnectionHdl := fbConnect.ConnectionHdl;			
			fbMethodGetHandle.Timeout := T#10s;

			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Success
			IF fbMethodGetHandle.Done THEN
				fbMethodGetHandle.Execute := FALSE;
				PowerPanel.Diag.Step := tpMETHOD_CALL;

				// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
				// Go to error state
			ELSIF fbMethodGetHandle.Error THEN
				fbMethodGetHandle.Execute := FALSE;
				PowerPanel.Diag.StatusId := fbMethodGetHandle.ErrorID;
				PowerPanel.Diag.StatusText := 'Error method handle';
				PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
				PowerPanel.Diag.Step := tpERROR;
			END_IF
	
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Call method
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpMETHOD_CALL:
			// Set parameters for function call
			fbMethodCall.Execute := TRUE;
			fbMethodCall.ConnectionHdl := fbConnect.ConnectionHdl;
			fbMethodCall.MethodHdl := fbMethodGetHandle.MethodHdl;
			fbMethodCall.Timeout := T#10s;

			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Success
			IF fbMethodCall.Done THEN
				fbMethodCall.Execute := FALSE;
				PowerPanel.Diag.Step := tpMETHOD_RELEASE;

				// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
				// Go to error state
			ELSIF fbMethodCall.Error THEN
				fbMethodCall.Execute := FALSE;
				PowerPanel.Diag.StatusId := fbMethodCall.ErrorID;
				PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
				PowerPanel.Diag.StatusText := 'Error executing method. Make sure parameter are correct';
				PowerPanel.Diag.Step := tpERROR;
			END_IF
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Release method handle
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpMETHOD_RELEASE:
			// Set parameters for function call
			fbMethodReleaseHandle.Execute := TRUE;
			fbMethodReleaseHandle.ConnectionHdl := fbConnect.ConnectionHdl;
			fbMethodReleaseHandle.MethodHdl := fbMethodGetHandle.MethodHdl;
			fbMethodReleaseHandle.Timeout := T#10s;
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Success
			IF fbMethodReleaseHandle.Done THEN
				fbMethodReleaseHandle.Execute := FALSE;
				
				// Disconnect when system was restarted
				IF PowerPanel.Method.Type = RestartSystem OR PowerPanel.Method.Type = StartUpdate THEN
					PowerPanel.Diag.Step := tpDISCONNECT;
				ELSE
					PowerPanel.Diag.Step := tpREADY;
				END_IF
				PowerPanel.Method.Type := NoMethod;
				
				// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
				// Go to error state
			ELSIF fbMethodReleaseHandle.Error THEN
				fbMethodReleaseHandle.Execute := FALSE;
				PowerPanel.Diag.StatusId := fbMethodReleaseHandle.ErrorID;
				PowerPanel.Diag.StatusText := 'Error method release';
				PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
				PowerPanel.Diag.Step := tpDISCONNECT;
			END_IF
							
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Release monitored items
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpMONITORLIST_REMOVE:
			// Set parameters for function call
			fbMonitoredItemRemoveList.Execute := TRUE;
			fbMonitoredItemRemoveList.SubscriptionHdl := fbSubscriptionCreate.SubscriptionHdl;
			fbMonitoredItemRemoveList.MonitoredItemHdlCount := VariablesReadIndex;
			fbMonitoredItemRemoveList.MonitoredItemHdls := fbMonitoredItemAddList.MonitoredItemHdls;
			fbMonitoredItemRemoveList.Timeout := T#10s;
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Success
			IF fbMonitoredItemRemoveList.Done THEN
				fbMonitoredItemRemoveList.Execute := FALSE;
				PowerPanel.Diag.Step := tpSUBSCRIPTION_DELETE;

				// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
				// Go to error state
			ELSIF fbMonitoredItemRemoveList.Error THEN
				fbMonitoredItemRemoveList.Execute := FALSE;
				PowerPanel.Diag.StatusId := fbMonitoredItemRemoveList.ErrorID;
				PowerPanel.Diag.StatusText := 'Error removing monitored items';
				PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
				PowerPanel.Diag.Step := tpDISCONNECT;
			END_IF		
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Delet subsciption
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpSUBSCRIPTION_DELETE:
			// Set parameters for function call
			fbSubscriptionDelete.Execute := TRUE;
			fbSubscriptionDelete.SubscriptionHdl := fbSubscriptionCreate.SubscriptionHdl;
			fbSubscriptionDelete.Timeout := T#10s;
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Success
			IF fbSubscriptionDelete.Done THEN
				fbSubscriptionDelete.Execute := FALSE;
				PowerPanel.Diag.Step := tpHANDLELIST_RELEASE;

				// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
				// Go to error state
			ELSIF fbSubscriptionDelete.Error THEN
				fbSubscriptionDelete.Execute := FALSE;
				PowerPanel.Diag.StatusId := fbSubscriptionDelete.ErrorID;
				PowerPanel.Diag.StatusText := 'Error deleting subscription';
				PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
				PowerPanel.Diag.Step := tpDISCONNECT;
			END_IF
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Release handles
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpHANDLELIST_RELEASE:
			// Set parameters for function call
			fbNodeReleaseHandleList.Execute := TRUE;
			fbNodeReleaseHandleList.ConnectionHdl := fbConnect.ConnectionHdl;
			fbNodeReleaseHandleList.NodeHdls := fbNodeGetHandleList.NodeHdls;
			fbNodeReleaseHandleList.NodeHdlCount := VariablesReadIndex;
			fbNodeReleaseHandleList.Timeout := T#10s;
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Success
			IF fbNodeReleaseHandleList.Done THEN
				fbNodeReleaseHandleList.Execute := FALSE;
				PowerPanel.Diag.Step := tpDISCONNECT;

				// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
				// Go to error state
			ELSIF fbNodeReleaseHandleList.Error THEN
				fbNodeReleaseHandleList.Execute := FALSE;
				PowerPanel.Diag.StatusId := fbNodeReleaseHandleList.ErrorID;
				PowerPanel.Diag.StatusText := 'Error releasing handles';
				PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
				PowerPanel.Diag.Step := tpDISCONNECT;
			END_IF
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Disconnect from panel
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpDISCONNECT:
			// Set parameters for function call
			fbDisconnect.Execute := TRUE;
			fbDisconnect.ConnectionHdl := fbConnect.ConnectionHdl;
			fbDisconnect.Timeout := T#10s;
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Ignore errors during disconnect
			IF fbDisconnect.Done OR fbDisconnect.Error THEN
				fbDisconnect.Execute := FALSE;

				brsmemset(ADR(PowerPanel.Data), 0, SIZEOF(PowerPanel.Data));
				PowerPanel.Command.Disconnect := FALSE;
				PowerPanel.Diag.IsConnected := FALSE;
				fbDisconnect.Execute := FALSE;

				IF PowerPanel.Diag.StatusId = UINT_TO_DWORD(ERR_FUB_BUSY) THEN
					PowerPanel.Diag.StatusId := UINT_TO_DWORD(ERR_OK);
					PowerPanel.Diag.StatusText := 'Disconnected';
					PowerPanel.Diag.Step := tpWAIT;
				ELSE
					PowerPanel.Diag.Step := tpERROR;
				END_IF
			END_IF
			
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Error state
			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
		tpERROR:
			PowerPanel.Command.Connect := FALSE;
			PowerPanel.Command.Disconnect := FALSE;

			// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
			// Command error reset
			IF PowerPanel.Command.ResetError THEN
				PowerPanel.Diag.ErrorStep := tpNONE;
				PowerPanel.Diag.StatusId := 0;
				PowerPanel.Diag.StatusText := '';
				PowerPanel.Method.Type := NoMethod;
				PowerPanel.Command.ResetError := FALSE;
				
				IF PowerPanel.Diag.IsConnected THEN
					PowerPanel.Diag.Step := tpREADY;
				ELSE
					PowerPanel.Diag.Step := tpWAIT;
				END_IF
			END_IF
	END_CASE
	
	// -----------------------------------------------------------------------------------------------------------------------------------------------------------------
	// Function calls
	fbConnect();		
	fbDisconnect();
	fbTranslatePath();
	fbSubscriptionCreate(PublishingInterval := PublishingInterval); 
	fbNodeGetHandleList();
	fbMonitoredItemAddList(TimeStamps := TimeStamps, RemainingValueCount := RemainingValueCount, MonitoringSettings := MonitoringParameters, Variables := VariablesReadInfo, ValuesChanged := ValuesChanged, NodeQualityIDs := NodeQualityIDs);
	fbWriteBulk();
	fbMethodGetHandle();
	fbMethodCall(InputArguments := InputArguments, OutputArguments := OutputArguments);	
	fbMethodReleaseHandle();
	fbMonitoredItemRemoveList();
	fbSubscriptionDelete();
	fbNodeReleaseHandleList();
 
END_PROGRAM