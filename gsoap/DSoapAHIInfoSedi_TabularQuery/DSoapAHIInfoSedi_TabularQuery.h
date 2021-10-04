#ifndef DSoapAHIInfoSediH
#define DSoapAHIInfoSediH

#include "soapzpcu_USCOREtest_USCOREfascia_USCOREdelayWSPortBindingProxy.h"

class DSoapAHIInfoSedi_TabularQuery {

    public:
        // Convert data names in uman-readable names
        typedef _ns1__zpcu_USCOREtest_USCOREfascia_USCOREdelay_USCORETabularQuery DQueryData;
        typedef std::vector<ns1__zpcu_USCOREtest_USCOREfascia_USCOREdelay_USCORETabularQueryResponseStructure *> DQueryRetItems;
        
        soap_status Call(DQueryData &Data, DQueryRetItems &RetItems);
        bool IsReady(DQueryData &Data);
        std::string GetLastErrorText(void);

    private:
        // GSoap generated client proxy
        zpcu_USCOREtest_USCOREfascia_USCOREdelayWSPortBindingProxy Client;
        // GSoap generated response container
        typedef _ns1__zpcu_USCOREtest_USCOREfascia_USCOREdelay_USCORETabularQueryResponse DQueryResp;
};

#endif
