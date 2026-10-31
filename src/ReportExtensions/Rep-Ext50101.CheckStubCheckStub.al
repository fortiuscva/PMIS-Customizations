reportextension 50101 "PMIS Check (Stub/Check/Stub)" extends "Check (Stub/Check/Stub)"
{
    RDLCLayout = './src/ReportExtensions/Layouts/CheckStubCheckStub.rdl';
    dataset
    {
        add(GenJnlLine)
        {
            column(PMISAccountNo; Vendor."Our Account No.") { }
            column(PMISVendDescription; Vendor.Name) { }
            column(PMISPostingDate; "Posting Date") { }
        }
        modify(GenJnlLine)
        {
            trigger OnAfterAfterGetRecord()

            begin
                Clear(Vendor);

                if GenJnlLine.Amount = 0 then
                    CurrReport.Skip();

                if not Vendor.Get(GenJnlLine."Account No.") then
                    CurrReport.Skip();
            end;
        }
    }
    var
        Vendor: Record Vendor;
}
