pageextension 50101 "PMIS Payment Journal" extends "Payment Journal"
{
    layout
    {
        addafter("Account No.")
        {

            field("PMIS Print Remittance"; Rec."PMIS Print Remittance")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Print Remittance field.', Comment = '%';
                Editable = false;
                DrillDown = true;

                trigger OnDrillDown()
                var
                    StubReport: Report "PMIS Stub Information";
                    GenJnlLine: Record "Gen. Journal Line";
                begin
                    if Rec."PMIS Print Remittance" then begin
                        GenJnlLine := Rec;
                        GenJnlLine.SetRecFilter();
                        StubReport.SetTableView(GenJnlLine);
                        StubReport.SetJournalBatch(Rec."Journal Template Name", Rec."Journal Batch Name");
                        StubReport.UseRequestPage(false);
                        StubReport.RunModal();
                    end;
                end;
            }
        }

    }
    actions
    {
        addlast(Processing)
        {
            action("PMIS Stub Information")
            {
                ApplicationArea = All;
                Caption = 'Print Stub Information';
                ToolTip = 'Print stub information for eligible computer-check payment lines in the current journal batch.';
                Image = Print;
                Promoted = true;
                PromotedCategory = Report;

                trigger OnAction()
                var
                    StubReport: Report "PMIS Stub Information";
                begin
                    Rec.TestField("Journal Template Name");
                    Rec.TestField("Journal Batch Name");

                    StubReport.SetJournalBatch(
                        Rec."Journal Template Name",
                        Rec."Journal Batch Name");

                    StubReport.RunModal();
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        Rec.UpdatePrintRemittance(Rec);
    end;
}
