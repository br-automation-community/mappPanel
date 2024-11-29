The task uses the variable structure 'PowerPanel' to communicate with the outside world.

## Command structure

 The structure *PowerPanel* looks as follows:

<table>

    <tr>
        <th width="100">Level 1</th>
        <th>Level 2</th>
        <th>Level Description</th>
    </tr>
    <tr>
        <td>Command</td>
        <td colspan="3">Trigger a command. The command is reset to false when the execution is finished.</td>
    </tr>
    <tr>
        <td></td>
        <td>Connect</td>
        <td colspan="3">Connect to the T-Panel.</td>
    </tr>
    <tr>
        <td></td>
        <td>Disconnect</td>
        <td colspan="3">Disconnect from the T-Panel.</td>
    </tr>
    <tr>
        <td></td>
        <td>Write</td>
        <td colspan="3">Write pending data.</td>
    </tr>
    <tr>
        <td></td>
        <td>ResetError</td>
        <td colspan="3">Reset errors.</td>
    </tr>
    <tr>
        <td>Data</td>
        <td colspan="3">This structure contains alle the OPC UA data that is available from the panel. See the corresponding panel documentation for details. See appendix for a collection of links.</td>
    </tr>
    <tr>
        <td>Method</td>
        <td colspan="3">This structure allows you to call methods (functions) on the connected panel.</td>
    </tr>
    <tr>
        <td></td>
        <td>Type</td>
        <td colspan="3">The function that is called on the panel. The method is called as soon as it is selected. See the corresponding panel documentation for more details on OPC UA methods.</td>
    </tr>
    <tr>
        <td></td>
        <td>BuzzerDuration</td>
        <td colspan="3">Parameter for method 'BuzzerWithPara'.</td>
    </tr>
    <tr>
        <td></td>
        <td>BuzzerFrequency</td>
        <td colspan="3">Parameter for method 'BuzzerWithPara'.</td>
    </tr>
    <tr>
        <td></td>
        <td>ActualTime</td>
        <td colspan="3">Parameter for method 'SetTime'.</td>
    </tr>
    <tr>
        <td></td>
        <td>Brightness</td>
        <td colspan="3">Parameter for method 'SetBrightness' and 'SetBrightnessUnlimited'.</td>
    </tr>
    <tr>
        <td>Parameter</td>
        <td colspan="3">Structure with parameters.</td>
    </tr>
    <tr>
        <td></td>
        <td>PanelIP</td>
        <td colspan="3">Panel IP address.</td>
    </tr>
    <tr>
        <td></td>
        <td>PanelType</td>
        <td colspan="3">Use one of the following types: T30, T50, FT50, T80</td>
    </tr>
    <tr>
        <td>Diag</td>
        <td colspan="3">Structure with diagnostic information.</td>
    </tr>
    <tr>
        <td></td>
        <td>PingOK</td>
        <td colspan="3">Indicates that the IP from Parameter.PanelIP can be pinged.</td>
    </tr>
    <tr>
        <td></td>
        <td>IsConnected</td>
        <td colspan="3">Indicates that a connection was established.</td>
    </tr>
    <tr>
        <td></td>
        <td>PendingWrites</td>
        <td colspan="3">Indicates that at least one data point was changed. Call the write command to send the data back to panel.</td>
    </tr>
    <tr>
        <td></td>
        <td>Step</td>
        <td colspan="3">Current state machine step.</td>
    </tr>
    <tr>
        <td></td>
        <td>StatusText</td>
        <td colspan="3">Shows the state information as text or error information.</td>
    </tr>
    <tr>
        <td></td>
        <td>StatusId</td>
        <td colspan="3">Shows busy states or error number.</td>
    </tr>
    <tr>
        <td></td>
        <td>VariableErrors</td>
        <td colspan="3">List of the first 10 data points that could not be connected.</td>
    </tr>
    <tr>
        <td></td>
        <td>VariableErrorsIndex</td>
        <td colspan="3">Total number of data points that could not be connected.</td>
    </tr>
        <tr>
        <td></td>
        <td>VisHelper...</td>
        <td colspan="3">Variables to change visibility in mappView.</td>
    </tr>
        <tr>
        <td></td>
        <td>ErrorStep</td>
        <td colspan="3">State machine step where the error occurred.</td>
    </tr>

</table>

## Error handling

The task generates the following list of error messages. All other error numbers are generated from included libraries that can be found in the Automation Studio help.

| No | Constant | Text |
|---|---|---|
| 10000 | ERR_PANEL_NO_DATA_MODULE  | The data module with the corresponding OPC UA tags is missing |
| 10001 | ERR_PANEL_IP_EMPTY  | IP address was not set |
| 10002 | ERR_PANEL_PANEL_TYPE_EMPTY  | Panel type was not set |
| 10003 | ERR_PANEL_FIRST_READ  | First read timed out |
| 10003 | ERR_PANEL_CONNECTION_LOST  | Connection to panel was interrupted  |
| 10003 | ERR_PANEL_METHOD_NOT_FOUND  | The method does not exist on the corresponding panel  |

## Data module

The task uses a data module that contains all the OPC UA variables that are connected. The data modules has the following structure:

|Browsepath|Variable/Argument|Argument|NameSpaceIndex|Identifier|Access|
|---|---|---|---|---|---|
|/0: Objects/0: Server/0: ServerStatus/0: CurrentTime|PowerPanel. Data. Time. CurrentDateTime|""|0x0000|""|"S"|

Not all variables may exist on every panel. The variable *PowerPanel. Diag. VariableErrors* contains the first 10 variables that could not be connected. See [appendix](appendix.md) for more details.

## Calling methods

The following methods can be called on the panel:

* AwakePanel
* RestartSystem
* StartRemoteAccess
* StopRemoteAccess
* SaveConfiguration
* LoadConfiguration
* StartUpdate
* BuzzerDefault
* BuzzerWithPara
* SetBrightness
* SetBrightnessUnlimited
* SetTime

The method RestartSystem and StartUpdate automatically disconnect the connection. The connection must be re-established after the panel rebooted. Wait a few extra seconds after restart before reconnecting.

**<span style="color:red">Important Note:</span>** The method is executed immediately when the type was changed and set back to 'NoMethod' when it was executed.

## Changing panel data

The sample allows you to change the data on the panel. The the panel manual on what data can be changed and what is read only. When parameters is changed it is not written until the command 'Write' is executed. The command 'Write' is reset to false when the execution is finished. The variable 'PowerPanel. Diag. PendingWrites' is set to true when at least one data point was changed. Many parameter changes require a restart of the panel to take affect. The following procedure is recommended:

* Change the parameter
* Call method 'SaveConfiguration'
* Call method 'RestartSystem'

**<span style="color:red">Important Note:</span>** Make sure that the parameter change does not break the connection after reboot. For example, changing the IP address may break the connection if the IP address is not set correctly. Changing the startup mode to 'ServiceMode' will also break the connection because the panel will not start the OPC UA server.
