#include <bur/plctypes.h>

typedef struct Browse_type
{
	plcstring BrowsePath[80];
	plcstring VariableName[80];
	plcstring Argument[80];
	unsigned short NamespaceIndex;
	plcstring Identifier[80];
	plcstring Access[2];
} BrowseType;
