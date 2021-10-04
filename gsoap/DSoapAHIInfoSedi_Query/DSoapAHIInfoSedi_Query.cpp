#include "DSoapAHIInfoSedi_Query.h"
#include "zpcu_USCOREtest_USCOREfascia_USCOREdelayWSPortBinding.nsmap"

// class generated from wsdl source:
// http://192.168.1.224:8180/ahi_test/servlet/SQLDataProviderServer/zpcu_test_fascia_delay?wsdl

soap_status DSoapAHIInfoSedi_Query::Call(DQueryData &Data, DQueryRetItems &RetItems)
{
    DQueryResp QueryResp;
    soap_status ret=Client.zpcu_USCOREtest_USCOREfascia_USCOREdelay_USCOREQuery(&Data,QueryResp);
    if (QueryResp.Records) {
        RetItems=QueryResp.Records->item;
    }

    return(ret);
}

bool DSoapAHIInfoSedi_Query::IsReady(DQueryData &Data)
{
    DQueryRetItems Items;

    soap_status ret=Call(Data,Items);
    if (ret != 0) {
        return false;
    }
    return true;
}

std::string DSoapAHIInfoSedi_Query::GetLastErrorText(void)
{
    std::string s(*soap_faultstring(Client.soap));
    return s;
}
