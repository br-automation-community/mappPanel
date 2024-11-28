ACTION DefineVariablesRead:
	IF (fbGetBrowsePath.status = ERR_OK) THEN
		j := 0;
		FOR i := 0 TO VariablesTotalIndex - 1 DO
			pBrowseVar ACCESS (fbGetBrowsePath.pDatObjMem + (i * SIZEOF(pBrowseVar)));			
			IF (pBrowseVar.Identifier <> '') AND (pBrowseVar.Access <> 'M') THEN
				UANodeIDMonitor[j].NamespaceIndex := pBrowseVar.NamespaceIndex;
				UANodeIDMonitor[j].IdentifierType := UAIdentifierType_Numeric;
				UANodeIDMonitor[j].Identifier := pBrowseVar.Identifier;
				VariablesReadInfo[j] := '::';
				VariablesReadInfo[j] := CONCAT(VariablesReadInfo[j], TaskName);
				VariablesReadInfo[j] := CONCAT(VariablesReadInfo[j], ':');
				VariablesReadInfo[j] := CONCAT(VariablesReadInfo[j], pBrowseVar.VariableName);
				j := j + 1;
			END_IF
			IF (j > INDEX_LIST) THEN
				EXIT;
			END_IF		
		END_FOR
		IF j > 0 THEN
			VariablesReadIndex := j - 1;
		END_IF
	END_IF
END_ACTION

ACTION DefineVariablesWrite:
	DataShadow;
	IF (fbGetBrowsePath.status = ERR_OK) THEN
		j := 0;
		FOR i := 0 TO VariablesTotalIndex - 1 DO
			pBrowseVar ACCESS (fbGetBrowsePath.pDatObjMem + (i * SIZEOF(pBrowseVar)));
			IF (pBrowseVar.Identifier <> '') AND (pBrowseVar.Access = 'W') THEN
				// Get variable details
				VariablesWriteInfo[j].ObjectIndex := i;				
				
				VariableName := '::';
				VariableName := CONCAT(VariableName, TaskName);
				VariableName := CONCAT(VariableName, ':');
				VariableName := CONCAT(VariableName, pBrowseVar.VariableName);		
				VariableStatus := PV_xgetadr(ADR(VariableName), ADR(VariablesWriteInfo[j].Adr), ADR(VariablesWriteInfo[j].DataLen));
				
				// Make sure variable exists
				IF VariableStatus = 0 THEN
					VariableName := '::';
					VariableName := CONCAT(VariableName, TaskName);
					VariableName := CONCAT(VariableName, ':');
					VariableName := CONCAT(VariableName, REPLACE(pBrowseVar.VariableName, 'DataShadow', 15, 1));		
					VariableStatus := PV_xgetadr(ADR(VariableName), ADR(VariablesWriteInfo[j].AdrShadow), ADR(VariablesWriteInfo[j].DataLen));

					j := j + 1;
				ELSE
					PowerPanel.Diag.StatusId := UINT_TO_DWORD(VariableStatus);
					PowerPanel.Diag.StatusText := VariableName;
					EXIT;
				END_IF
				
			END_IF
			IF (j > INDEX_LIST) THEN
				EXIT;
			END_IF				
		END_FOR

		VariablesWriteIndex := j;
	END_IF
END_ACTION

ACTION CheckValueChange:
	PowerPanel.Diag.PendingWrites := FALSE;
	
	IF (fbGetBrowsePath.status = ERR_OK) THEN	
		j := 0;
		brsmemset(ADR(VariablesChanged), 0 , SIZEOF(VariablesChanged));
		
		FOR i := 0 TO VariablesWriteIndex - 1 DO
			IF brsmemcmp(VariablesWriteInfo[i].Adr, VariablesWriteInfo[i].AdrShadow, VariablesWriteInfo[i].DataLen) <> 0 THEN
				pBrowseVar ACCESS (fbGetBrowsePath.pDatObjMem + (VariablesWriteInfo[i].ObjectIndex * SIZEOF(pBrowseVar)));		
				UANodeIDWrite[j].Identifier := pBrowseVar.Identifier;
				UANodeIDWrite[j].NamespaceIndex := pBrowseVar.NamespaceIndex;
				UANodeIDWrite[j].IdentifierType := UAIdentifierType_Numeric;
				VariablesChanged[j] := VariablesReadInfo[VariablesWriteInfo[i].ObjectIndex];
				
				PowerPanel.Diag.PendingWrites := TRUE;

				j := j + 1;
				IF (j > INDEX_LIST) THEN
					EXIT;
				END_IF
			END_IF		
		END_FOR
	
		VariablesChangeIndex := j;
	END_IF
END_ACTION

ACTION DefineMethod:
	// Set object ID
	FOR i:=0 TO VariablesTotalIndex - 1 DO
		pBrowseVar ACCESS (fbGetBrowsePath.pDatObjMem + (i * SIZEOF(pBrowseVar)));
		MethodIndex := FIND(pBrowseVar.BrowsePath,'/2:MethodSet');
		MethodPathLen := LEN(pBrowseVar.BrowsePath);
		IF (MethodIndex > 0) AND (MethodPathLen <= 12) THEN
			fbMethodGetHandle.ObjectNodeID.Identifier := pBrowseVar.Identifier;
			fbMethodGetHandle.ObjectNodeID.NamespaceIndex := pBrowseVar.NamespaceIndex;
			fbMethodGetHandle.ObjectNodeID.IdentifierType := UAIdentifierType_Numeric;
			EXIT;
		END_IF
	END_FOR
	MethodSetBP := '/2:MethodSet';
	
	// Set method ID parameters
	brsmemset(ADR(InputArguments),0,SIZEOF(InputArguments));			
	IF PowerPanel.Method.Type = StartRemoteAccess THEN
		MethodCall := '/2:MethodSet/4:StartRemoteAccess';
	ELSIF PowerPanel.Method.Type = StopRemoteAccess THEN
		MethodCall := '/2:MethodSet/4:StopRemoteAccess';
	ELSIF PowerPanel.Method.Type = SaveConfiguration THEN
		MethodCall := '/2:MethodSet/4:SaveConfiguration';
	ELSIF PowerPanel.Method.Type = LoadConfiguration THEN
		MethodCall := '/2:MethodSet/4:LoadConfiguration';
	ELSIF PowerPanel.Method.Type = AwakePanel THEN
		MethodCall := '/2:MethodSet/4:AwakePanel';
	ELSIF PowerPanel.Method.Type = RestartSystem THEN
		MethodCall := '/2:MethodSet/4:RestartSystem';
	ELSIF PowerPanel.Method.Type = StartUpdate THEN
		MethodCall := '/2:MethodSet/4:StartUpdate';
	ELSIF PowerPanel.Method.Type = BuzzerDefault THEN
		MethodCall := '/2:MethodSet/4:BuzzerDefault';
	ELSIF PowerPanel.Method.Type = SetBrightness THEN
		MethodCall := '/2:MethodSet/4:SetBrightness';
	ELSIF PowerPanel.Method.Type = SetBrightnessUnlimited THEN
		MethodCall := '/2:MethodSet/4:SetBrightnessUnlimited';		
	ELSIF PowerPanel.Method.Type = SetTime THEN
		MethodCall := '/2:MethodSet/4:SetTime';			
	ELSIF PowerPanel.Method.Type = BuzzerWithPara THEN
		MethodCall := '/2:MethodSet/4:BuzzerWithPara';										
	END_IF
	
	// Find method ID details
	FOR i:=0 TO (VariablesTotalIndex - 1) DO
		pBrowseVar ACCESS (fbGetBrowsePath.pDatObjMem + (i * SIZEOF(pBrowseVar)));
		MethodIndex := FIND(pBrowseVar.BrowsePath, MethodCall);
		IF (MethodIndex > 0) THEN
			fbMethodGetHandle.MethodNodeID.Identifier := pBrowseVar.Identifier;
			fbMethodGetHandle.MethodNodeID.NamespaceIndex := pBrowseVar.NamespaceIndex;
			fbMethodGetHandle.MethodNodeID.IdentifierType := UAIdentifierType_Numeric;
			
			IF PowerPanel.Method.Type = SetBrightness THEN
				MethodCall := '/2:MethodSet/4:SetBrightness';
				InputArguments[0].Name := 'Brightness';
				InputArguments[0].Value := '::';
				InputArguments[0].Value := CONCAT(InputArguments[0].Value,TaskName);
				InputArguments[0].Value := CONCAT(InputArguments[0].Value,':');				
				InputArguments[0].Value := CONCAT(InputArguments[0].Value,pBrowseVar.VariableName);	
			ELSIF PowerPanel.Method.Type = SetBrightnessUnlimited THEN
				MethodCall := '/2:MethodSet/4:SetBrightnessUnlimited';	
				InputArguments[0].Name := 'BrightnessUnlimited';
				InputArguments[0].Value := '::';
				InputArguments[0].Value := CONCAT(InputArguments[0].Value,TaskName);
				InputArguments[0].Value := CONCAT(InputArguments[0].Value,':');			
				InputArguments[0].Value := CONCAT(InputArguments[0].Value,pBrowseVar.VariableName);		
			ELSIF PowerPanel.Method.Type = SetTime THEN
				MethodCall := '/2:MethodSet/4:SetTime';		
				InputArguments[0].Name := 'Time';
				InputArguments[0].Value := '::';
				InputArguments[0].Value := CONCAT(InputArguments[0].Value,TaskName);
				InputArguments[0].Value := CONCAT(InputArguments[0].Value,':');			
				InputArguments[0].Value := CONCAT(InputArguments[0].Value,pBrowseVar.VariableName);		
			ELSIF PowerPanel.Method.Type = BuzzerWithPara THEN
				MethodCall := '/2:MethodSet/4:BuzzerWithPara';			
				InputArguments[0].Name := 'Frequency';
				InputArguments[0].Value := '::';
				InputArguments[0].Value := CONCAT(InputArguments[0].Value,TaskName);
				InputArguments[0].Value := CONCAT(InputArguments[0].Value,':');				
				InputArguments[0].Value := CONCAT(InputArguments[0].Value,pBrowseVar.VariableName);
				InputArguments[1].Name := 'Duration';
				InputArguments[1].Value := '::';
				InputArguments[1].Value := CONCAT(InputArguments[1].Value,TaskName);
				InputArguments[1].Value := CONCAT(InputArguments[1].Value,':');				
				InputArguments[1].Value := CONCAT(InputArguments[1].Value,pBrowseVar.Argument);
			END_IF
			EXIT;
		END_IF
	END_FOR
	
	// Create error when method was not found
	IF MethodIndex = 0 THEN
		PowerPanel.Diag.StatusId := ERR_PANEL_METHOD_NOT_FOUND;
		PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
		PowerPanel.Diag.StatusText := 'Method type not found in data module';
		PowerPanel.Diag.Step := tpERROR;
	END_IF

END_ACTION

ACTION CheckPing:
	// Trigger ping request
	PingTimer.IN := TRUE;
	PingTimer.PT := PING_TIMEOUT;
	PingTimer();
	
	IcmpPing_0(enable := 1, pHost := ADR(PowerPanel.Parameter.PanelIP), timeout := PING_TIMEOUT);

	// Ping was OK
	IF(IcmpPing_0.status = ERR_OK) THEN
		PingTimer(IN := FALSE);
		PowerPanel.Diag.PingOk := TRUE;
	
	// Disconnect from share when ping failed
	ELSIF(IcmpPing_0.status <> ERR_FUB_BUSY) THEN
		PingTimer(IN := FALSE);
		PowerPanel.Diag.PingOk := FALSE;
		
		// Go to error state when connected
		IF PowerPanel.Diag.IsConnected THEN
			PowerPanel.Diag.IsConnected := FALSE;
			
			PowerPanel.Diag.StatusId := ERR_PANEL_CONNECTION_LOST;
			PowerPanel.Diag.ErrorStep := PowerPanel.Diag.Step;
			PowerPanel.Diag.StatusText := 'Connection is lost';
			PowerPanel.Diag.Step := tpERROR;
		END_IF
	END_IF
END_ACTION

