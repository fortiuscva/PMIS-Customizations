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
        addlast("&Payments")
        {
            action("PMIS Stub Information")
            {
                ApplicationArea = All;
                Caption = 'Print Stub Information';
                ToolTip = 'Print stub information for eligible computer-check payment lines in the current journal batch.';
                Image = Print;

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
            action("PMIS PrintCheck")
            {
                ApplicationArea = All;
                Caption = 'PMIS Print Check';
                ToolTip = 'Run the check report selected for the current payment journal batch.';
                Image = PrintCheck;
                Ellipsis = true;

                trigger OnAction()
                var
                    GenJournalLine: Record "Gen. Journal Line";
                begin
                    GenJournalLine.Reset();
                    GenJournalLine.Copy(Rec);
                    GenJournalLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                    GenJournalLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                    Report.RunModal(Report::"PMIS Check (Stub/Check/Stub)", true, false, GenJournalLine);
                    Codeunit.Run(Codeunit::"Adjust Gen. Journal Balance", Rec);
                end;
            }
        }
        addlast(Category_Category11)
        {
            actionref("PMISPrintCheck_Promote"; "PMIS PrintCheck")
            {
            }
            actionref("PMISPrintStubInformation_Promote"; "PMIS Stub Information")
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.UpdatePrintRemittance(Rec);
    end;
}
