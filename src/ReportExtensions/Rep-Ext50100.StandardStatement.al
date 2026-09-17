reportextension 50100 "PMIS Standard Statement" extends "Standard Statement"
{
    dataset
    {
        add(Integer)
        {
            column(PMISExternal_Doc_No_Caption; ExternalDocNoCaptionLbl)
            { }
        }
        add(DtldCustLedgEntries)
        {
            column(PMISExternalDocNo; ExternalDocNo)
            { }
        }
        modify(DtldCustLedgEntries)
        {
            trigger OnAfterAfterGetRecord()
            var
                CustLedgeEntryRec: Record "Cust. Ledger Entry";
            begin
                Clear(ExternalDocNo);
                if CustLedgeEntryRec.Get(DtldCustLedgEntries."Cust. Ledger Entry No.") then
                    ExternalDocNo := CustLedgeEntryRec."External Document No.";
            end;
        }
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
        ExternalDocNo: Code[35];
}
