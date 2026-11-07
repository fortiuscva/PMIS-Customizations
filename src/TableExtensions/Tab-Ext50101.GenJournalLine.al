tableextension 50101 "PMIS Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        field(50100; "PMIS Applied Entries Count"; Integer)
        {
            Caption = 'Applied Entries Count';
            FieldClass = FlowField;
            CalcFormula = Count("Vendor Ledger Entry" where(
                "Vendor No." = field("Account No."),
                "Applies-to ID" = field("Applies-to ID")));
            Editable = false;
        }
        field(50101; "PMIS Print Remittance"; Boolean)
        {
            Caption = 'Print Remittance';
            DataClassification = CustomerContent;
        }
    }
    procedure UpdatePrintRemittance(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.CalcFields("PMIS Applied Entries Count");

        GenJournalLine."PMIS Print Remittance" :=
            GenJournalLine."PMIS Applied Entries Count" > 10;
    end;
}
