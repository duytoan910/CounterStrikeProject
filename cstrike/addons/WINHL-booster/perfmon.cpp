#include "booster.h"


PDH_STATUS (__stdcall * pPdhOpenQueryA)(LPCTSTR, DWORD, HQUERY *);
PDH_STATUS (__stdcall * pPdhCloseQuery)(HQUERY);
PDH_STATUS (__stdcall * pPdhAddCounterA)(HQUERY, LPCTSTR, DWORD, HCOUNTER *);
PDH_STATUS (__stdcall * pPdhRemoveCounter)(HCOUNTER);
PDH_STATUS (__stdcall * pPdhCollectQueryData)(HQUERY);
PDH_STATUS (__stdcall * pPdhGetFormattedCounterValue)(HCOUNTER, DWORD, LPDWORD, PPDH_FMT_COUNTERVALUE);

int PerfmonInit = 0;

bool InitializePerfmon(void)
{
	if(PerfmonInit==1)
		return(true);
	else if(PerfmonInit==2)
		return(false);
	
	HMODULE hPdhDll = LoadLibrary("pdh.dll");
	if(!hPdhDll)
	{
		PerfmonInit = 2;
		return(false);
	}
	
	*(FARPROC*)&pPdhOpenQueryA               = GetProcAddress(hPdhDll, "PdhOpenQueryA");
	*(FARPROC*)&pPdhCloseQuery               = GetProcAddress(hPdhDll, "PdhCloseQuery");
	*(FARPROC*)&pPdhAddCounterA              = GetProcAddress(hPdhDll, "PdhAddCounterA");
	*(FARPROC*)&pPdhRemoveCounter            = GetProcAddress(hPdhDll, "PdhRemoveCounter");
	*(FARPROC*)&pPdhCollectQueryData         = GetProcAddress(hPdhDll, "PdhCollectQueryData");
	*(FARPROC*)&pPdhGetFormattedCounterValue = GetProcAddress(hPdhDll, "PdhGetFormattedCounterValue");
	
	if(!pPdhOpenQueryA || !pPdhCloseQuery ||
		!pPdhAddCounterA || !pPdhRemoveCounter ||
		!pPdhCollectQueryData || !pPdhGetFormattedCounterValue)
	{
		PerfmonInit = 2;
		return(false);
	}
	else
	{
		PerfmonInit = 1;
		return(true);
	}
}


//
//cpu usage monitor by Buzz_Kill <buzzkill@100acrebloodbath.com>
//
BOOL __fastcall OpenPDHProf( PPDHPROFSTRUCT pStruct ) 
{
	if(!InitializePerfmon()) return(FALSE);

    BOOL fRes = TRUE;
    __try {
        //if (pStruct->hQuery == NULL)
        //    fRes = FALSE;
        //else {
            if (ERROR_SUCCESS != pPdhOpenQueryA(NULL, 0, &(pStruct->hQuery))) {
                pStruct->hQuery = NULL;
                fRes = FALSE;
            }
        //}
    }
    __except(EXCEPTION_EXECUTE_HANDLER) {
        fRes = FALSE;
    }
    return fRes;
}

BOOL __fastcall ClosePDHProf( PPDHPROFSTRUCT pStruct )
{
	if(!InitializePerfmon()) return(FALSE);

    BOOL fRes = TRUE;
    __try {
        if (pStruct->hQuery == NULL)
            fRes = FALSE;
        else {
            if (ERROR_SUCCESS != pPdhCloseQuery(pStruct->hQuery)) {
                pStruct->hQuery = NULL;
                fRes = FALSE;
            }
        }
    }
    __except(EXCEPTION_EXECUTE_HANDLER) {
        fRes = FALSE;
    }
    return fRes;
}

BOOL __fastcall CreatePDHItem(LPTSTR lpszCounterName, PPDHPROFSTRUCT pStruct ) 
{
	if(!InitializePerfmon()) return(FALSE);

    BOOL fRes = TRUE;
    __try {
        if (OpenPDHProf(pStruct))
            fRes = (ERROR_SUCCESS == pPdhAddCounterA(
                                        pStruct->hQuery, 
                                        lpszCounterName, 
                                        0, 
                                        &(pStruct->hCounter)));
        else
            fRes = FALSE;
    }
    __except(EXCEPTION_EXECUTE_HANDLER) {
        fRes = FALSE;
    }
    return fRes;
}

BOOL __fastcall ClosePDHItem( PPDHPROFSTRUCT pStruct )
{
	if(!InitializePerfmon()) return(FALSE);

    BOOL fRes = TRUE;
    __try {
        fRes = (ERROR_SUCCESS == pPdhRemoveCounter(
                                    pStruct->hCounter));
        if (!ClosePDHProf(pStruct))
            fRes = FALSE;
    }
    __except(EXCEPTION_EXECUTE_HANDLER) {
        fRes = FALSE;
    }
    return fRes;
}

BOOL __fastcall PDHUpdateValue( HQUERY hQuery, HCOUNTER hCounter, PDWORD pdwValue )
{
	if(!InitializePerfmon()) return(FALSE);

    BOOL fRes = FALSE;
    PDH_FMT_COUNTERVALUE pdhFMTVal;
    __try {
        if (ERROR_SUCCESS == pPdhCollectQueryData(hQuery)) {
            if (ERROR_SUCCESS == pPdhGetFormattedCounterValue(
                                    hCounter, 
                                    PDH_FMT_LONG, 
                                    NULL, 
                                    &pdhFMTVal)) {
                if (pdhFMTVal.CStatus == ERROR_SUCCESS) {
                    *pdwValue = pdhFMTVal.longValue;
                    fRes = TRUE;
                }
            }
        }
    }
    __except(EXCEPTION_EXECUTE_HANDLER) {
        fRes = FALSE;
    }
    return fRes;
}

BOOL __fastcall PDHUpdate( PPDHPROFSTRUCT pStruct )
{
	if(!InitializePerfmon()) return(FALSE);

    BOOL fRes = TRUE;
    __try {
        fRes = PDHUpdateValue(
                       pStruct->hQuery, 
                       pStruct->hCounter, 
                       &(pStruct->dwValue));
    }
    __except(EXCEPTION_EXECUTE_HANDLER) {
        fRes = FALSE;
    }
    return fRes;
}

