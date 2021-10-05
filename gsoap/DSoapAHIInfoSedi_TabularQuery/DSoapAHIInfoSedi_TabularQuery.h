#ifndef DSoapAHIInfoSediH
#define DSoapAHIInfoSediH

#include "soapzpcu_qinfosedi_fascia_delay_wsWSPortBindingProxy.h"

class DSoapAHIInfoSedi_TabularQuery {

    public:
        // Convert data names in uman-readable names
        typedef _ns1__zpcu_qinfosedi_fascia_delay_ws_USCORETabularQuery DQueryData;
        typedef std::vector<ns1__zpcu_qinfosedi_fascia_delay_ws_USCORETabularQueryResponseStructure *> DQueryRetItems;
        
        soap_status Call(DQueryData &Data, DQueryRetItems &RetItems);
        bool IsReady(DQueryData &Data);
        std::string GetLastErrorText(void);

    private:
        // GSoap generated client proxy
        zpcu_qinfosedi_fascia_delay_wsWSPortBindingProxy Client;
        // GSoap generated response container
        typedef _ns1__zpcu_qinfosedi_fascia_delay_ws_USCORETabularQueryResponse DQueryResp;
};

#endif
