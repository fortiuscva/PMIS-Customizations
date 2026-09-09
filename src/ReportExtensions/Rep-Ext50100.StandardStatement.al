reportextension 50100 "PMIS Standard Statement" extends "Standard Statement"
{
    dataset
    {
        add(OverdueVisible)
        {
            column(PMISExternal_Document_No_Caption; ExternalDocNoCaptionLbl)
            { }
        }
        add(CustLedgEntry2)
        {
            column(PMISExternal_Document_No_; "External Document No.")
            { }
        }
    }
    var
        ExternalDocNoCaptionLbl: Label 'External Document No.';
}
