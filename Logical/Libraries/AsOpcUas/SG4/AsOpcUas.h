/* Automation Studio generated header file */
/* Do not edit ! */

#ifndef _ASOPCUAS_
#define _ASOPCUAS_
#ifdef __cplusplus
extern "C" 
{
#endif

#include <bur/plctypes.h>

#ifndef _BUR_PUBLIC
#define _BUR_PUBLIC
#endif
/* Datatypes and datatypes of function blocks */
typedef enum UaMethodOperateAction
{	UaMoa_CheckIsCalled = 0,
	UaMoa_Finished = 1
} UaMethodOperateAction;

typedef struct UaSrv_MethodOperateInternal
{	plcbit Busy;
	plcbit Execute;
	unsigned long ModuleId;
	unsigned long CallId;
	unsigned short NamespaceIndex;
	unsigned char Reserved[30];
} UaSrv_MethodOperateInternal;

typedef struct UaSrv_MethodCreateInternal
{	plcbit Busy;
	plcbit Execute;
	unsigned long ModuleId;
	unsigned char Reserved[32];
} UaSrv_MethodCreateInternal;

typedef struct UaSrv_MethodDeleteInternal
{	plcbit Busy;
	plcbit Execute;
	unsigned long ModuleId;
	unsigned char Reserved[32];
} UaSrv_MethodDeleteInternal;

typedef struct UaSrv_FireEventInternal
{	plcbit Busy;
	plcbit Execute;
	unsigned long ModuleId;
	unsigned char Reserved[32];
} UaSrv_FireEventInternal;

typedef struct UaSrv_GetNamespaceIndexInternal
{	plcbit Busy;
	plcbit Execute;
	unsigned long ModuleId;
	unsigned char Reserved[32];
} UaSrv_GetNamespaceIndexInternal;

typedef struct UaSrv_DateTimeType
{	plcdt DateTime;
	unsigned long NanoSeconds;
} UaSrv_DateTimeType;

typedef struct UaSrv_FireEventFieldType
{	plcstring BrowsePath[256];
	plcstring Variable[256];
	plcdword ErrorID;
} UaSrv_FireEventFieldType;

typedef struct UaSrv_MethodOperate
{
	/* VAR_INPUT (analog) */
	plcstring MethodName[256];
	enum UaMethodOperateAction Action;
	plcdword MethodResult;
	/* VAR_OUTPUT (analog) */
	plcdword ErrorID;
	/* VAR (analog) */
	struct UaSrv_MethodOperateInternal Internal;
	/* VAR_INPUT (digital) */
	plcbit Execute;
	/* VAR_OUTPUT (digital) */
	plcbit IsCalled;
	plcbit Done;
	plcbit Busy;
	plcbit Error;
} UaSrv_MethodOperate_typ;

typedef struct UaSrv_MethodCreate
{
	/* VAR_INPUT (analog) */
	plcstring MethodName[256];
	struct BrUaMethodArgument InputArguments[10];
	struct BrUaMethodArgument OutputArguments[10];
	/* VAR_OUTPUT (analog) */
	plcdword ErrorID;
	/* VAR (analog) */
	struct UaSrv_MethodCreateInternal Internal;
	/* VAR_INPUT (digital) */
	plcbit Execute;
	/* VAR_OUTPUT (digital) */
	plcbit Done;
	plcbit Busy;
	plcbit Error;
} UaSrv_MethodCreate_typ;

typedef struct UaSrv_MethodDelete
{
	/* VAR_INPUT (analog) */
	plcstring MethodName[256];
	/* VAR_OUTPUT (analog) */
	plcdword ErrorID;
	/* VAR (analog) */
	struct UaSrv_MethodDeleteInternal Internal;
	/* VAR_INPUT (digital) */
	plcbit Execute;
	/* VAR_OUTPUT (digital) */
	plcbit Done;
	plcbit Busy;
	plcbit Error;
} UaSrv_MethodDelete_typ;

typedef struct UaSrv_GetNamespaceIndex
{
	/* VAR_INPUT (analog) */
	plcstring NamespaceUri[256];
	/* VAR_OUTPUT (analog) */
	unsigned short NamespaceIndex;
	plcdword ErrorID;
	/* VAR (analog) */
	struct UaSrv_GetNamespaceIndexInternal Internal;
	/* VAR_INPUT (digital) */
	plcbit Execute;
	/* VAR_OUTPUT (digital) */
	plcbit Done;
	plcbit Busy;
	plcbit Error;
} UaSrv_GetNamespaceIndex_typ;

typedef struct UaSrv_FireEvent
{
	/* VAR_INPUT (analog) */
	struct UANodeID EventType;
	unsigned short EventFieldCount;
	/* VAR_OUTPUT (analog) */
	plcdword ErrorID;
	/* VAR_IN_OUT (analog and digital) */
	struct UaSrv_FireEventFieldType* EventFields;
	/* VAR (analog) */
	struct UaSrv_FireEventInternal Internal;
	/* VAR_INPUT (digital) */
	plcbit Execute;
	/* VAR_OUTPUT (digital) */
	plcbit Done;
	plcbit Busy;
	plcbit Error;
} UaSrv_FireEvent_typ;



/* Prototyping of functions and function blocks */
_BUR_PUBLIC void UaSrv_MethodOperate(struct UaSrv_MethodOperate* inst);
_BUR_PUBLIC void UaSrv_MethodCreate(struct UaSrv_MethodCreate* inst);
_BUR_PUBLIC void UaSrv_MethodDelete(struct UaSrv_MethodDelete* inst);
_BUR_PUBLIC void UaSrv_GetNamespaceIndex(struct UaSrv_GetNamespaceIndex* inst);
_BUR_PUBLIC void UaSrv_FireEvent(struct UaSrv_FireEvent* inst);
_BUR_PUBLIC UAServerState UaSrv_GetServerState(void);


/* Constants */
#ifdef _REPLACE_CONST
 #define UA_Bad_MonitoringQueueSize 2952790029U
 #define UA_Bad_ElementCount 2952790028U
 #define UA_Bad_VariableNameInvalid 2952790020U
 #define UA_Bad_SyncModeInvalid 2684355843U
 #define UA_Bad_MonitoredItemSyncMismatch 2684355842U
 #define UA_Bad_MonitoredItemInvalidHdl 2684355841U
 #define UA_Bad_SubscriptionInvalidHdl 2684355840U
 #define UA_Bad_AttributeIdInvalid 2684355585U
 #define UA_Bad_AttributeIdUnknown 2684355584U
 #define UA_Bad_MethodInvalidHdl 2684355331U
 #define UA_Bad_NodeInvalidHdl 2684355330U
 #define UA_Bad_ResultTooLong 2684355328U
 #define UA_Bad_NsNotFound 2684355072U
 #define UA_Bad_ConnectionInvalidHdl 2684354821U
 #define UA_Bad_FW_TempError 2684354562U
 #define UA_Bad_FW_PermanentError 2684354561U
 #define MAX_INDEX_EVENTFIELDSELECTION 63U
 #define MAX_INDEX_EVENTITEMLIST 63U
 #define MAX_INDEX_METHOD 63U
 #define MAX_INDEX_NAMESPACES 63U
 #define MAX_INDEX_BROWSERESULT 63U
 #define MAX_INDEX_BYTESTRING 1023U
 #define MAX_INDEX_RELATIVEPATH 15U
 #define MAX_INDEX_ARGUMENTS 9U
 #define MAX_INDEX_MONITORLIST 63U
 #define MAX_INDEX_NODELIST 63U
 #define MAX_INDEX_INDEXRANGE 7U
 #define MAX_INDEX_ARRAYDIMENSION 6U
 #define MAX_EVENT_FIELD_SELECTIONS 64U
 #define MAX_ELEMENTS_EVENTITEMLIST 64U
 #define MAX_ELEMENTS_METHOD 64U
 #define MAX_ELEMENTS_NAMESPACES 64U
 #define MAX_ELEMENTS_BROWSERESULT 64U
 #define MAX_ELEMENTS_RELATIVEPATH 16U
 #define MAX_ELEMENTS_ARGUMENTS 10U
 #define MAX_ELEMENTS_MONITORLIST 64U
 #define MAX_ELEMENTS_NODELIST 64U
 #define MAX_ELEMENTS_INDEXRANGE 8U
 #define MAX_ELEMENTS_ARRAYDIMENSION 7U
 #define MAX_LENGTH_LOCALEID 6U
 #define MAX_LENGTH_BYTESTRING 1024U
 #define MAX_LENGTH_ARGUMENT 64U
 #define MAX_LENGTH_VARIABLE 255U
 #define MAX_LENGTH_STRING 255U
 #define MAX_LENGTH_EVENTFIELDPATH 255U
 #define MAX_LENGTH_NAMESPACEURI 255U
 #define UA_Bad_MethodNameInvalid 2952790033U
 #define UA_Bad_DuplicateArgument 2952790034U
#else
 _GLOBAL_CONST unsigned long UA_Bad_MonitoringQueueSize;
 _GLOBAL_CONST unsigned long UA_Bad_ElementCount;
 _GLOBAL_CONST unsigned long UA_Bad_VariableNameInvalid;
 _GLOBAL_CONST unsigned long UA_Bad_SyncModeInvalid;
 _GLOBAL_CONST unsigned long UA_Bad_MonitoredItemSyncMismatch;
 _GLOBAL_CONST unsigned long UA_Bad_MonitoredItemInvalidHdl;
 _GLOBAL_CONST unsigned long UA_Bad_SubscriptionInvalidHdl;
 _GLOBAL_CONST unsigned long UA_Bad_AttributeIdInvalid;
 _GLOBAL_CONST unsigned long UA_Bad_AttributeIdUnknown;
 _GLOBAL_CONST unsigned long UA_Bad_MethodInvalidHdl;
 _GLOBAL_CONST unsigned long UA_Bad_NodeInvalidHdl;
 _GLOBAL_CONST unsigned long UA_Bad_ResultTooLong;
 _GLOBAL_CONST unsigned long UA_Bad_NsNotFound;
 _GLOBAL_CONST unsigned long UA_Bad_ConnectionInvalidHdl;
 _GLOBAL_CONST unsigned long UA_Bad_FW_TempError;
 _GLOBAL_CONST unsigned long UA_Bad_FW_PermanentError;
 _GLOBAL_CONST unsigned short MAX_INDEX_EVENTFIELDSELECTION;
 _GLOBAL_CONST unsigned short MAX_INDEX_EVENTITEMLIST;
 _GLOBAL_CONST unsigned short MAX_INDEX_METHOD;
 _GLOBAL_CONST unsigned short MAX_INDEX_NAMESPACES;
 _GLOBAL_CONST unsigned short MAX_INDEX_BROWSERESULT;
 _GLOBAL_CONST unsigned short MAX_INDEX_BYTESTRING;
 _GLOBAL_CONST unsigned short MAX_INDEX_RELATIVEPATH;
 _GLOBAL_CONST unsigned short MAX_INDEX_ARGUMENTS;
 _GLOBAL_CONST unsigned short MAX_INDEX_MONITORLIST;
 _GLOBAL_CONST unsigned short MAX_INDEX_NODELIST;
 _GLOBAL_CONST unsigned short MAX_INDEX_INDEXRANGE;
 _GLOBAL_CONST unsigned short MAX_INDEX_ARRAYDIMENSION;
 _GLOBAL_CONST unsigned short MAX_EVENT_FIELD_SELECTIONS;
 _GLOBAL_CONST unsigned short MAX_ELEMENTS_EVENTITEMLIST;
 _GLOBAL_CONST unsigned short MAX_ELEMENTS_METHOD;
 _GLOBAL_CONST unsigned short MAX_ELEMENTS_NAMESPACES;
 _GLOBAL_CONST unsigned short MAX_ELEMENTS_BROWSERESULT;
 _GLOBAL_CONST unsigned short MAX_ELEMENTS_RELATIVEPATH;
 _GLOBAL_CONST unsigned short MAX_ELEMENTS_ARGUMENTS;
 _GLOBAL_CONST unsigned short MAX_ELEMENTS_MONITORLIST;
 _GLOBAL_CONST unsigned short MAX_ELEMENTS_NODELIST;
 _GLOBAL_CONST unsigned short MAX_ELEMENTS_INDEXRANGE;
 _GLOBAL_CONST unsigned short MAX_ELEMENTS_ARRAYDIMENSION;
 _GLOBAL_CONST unsigned short MAX_LENGTH_LOCALEID;
 _GLOBAL_CONST unsigned short MAX_LENGTH_BYTESTRING;
 _GLOBAL_CONST unsigned short MAX_LENGTH_ARGUMENT;
 _GLOBAL_CONST unsigned short MAX_LENGTH_VARIABLE;
 _GLOBAL_CONST unsigned short MAX_LENGTH_STRING;
 _GLOBAL_CONST unsigned short MAX_LENGTH_EVENTFIELDPATH;
 _GLOBAL_CONST unsigned short MAX_LENGTH_NAMESPACEURI;
 _GLOBAL_CONST unsigned long UA_Bad_MethodNameInvalid;
 _GLOBAL_CONST unsigned long UA_Bad_DuplicateArgument;
#endif




#ifdef __cplusplus
};
#endif
#endif /* _ASOPCUAS_ */

