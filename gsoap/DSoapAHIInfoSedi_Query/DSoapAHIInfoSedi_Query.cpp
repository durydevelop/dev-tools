#include "DSoapAHIInfoSedi_Query.h"
#include "zpcu_qinfosedi_fascia_delay_wsWSPortBinding.nsmap"

// class generated from wsdl source:
// http://192.168.1.224:8080/ahi/servlet/SQLDataProviderServer/zpcu-qinfosedi-fascia-delay-ws?wsdl

soap_status DSoapAHIInfoSedi_Query::Call(DQueryData &Data, DQueryRetItems &RetItems)
{
    DQueryResp QueryResp;
    soap_status ret=Client.zpcu_qinfosedi_fascia_delay_ws_USCOREQuery(&Data,QueryResp);
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
