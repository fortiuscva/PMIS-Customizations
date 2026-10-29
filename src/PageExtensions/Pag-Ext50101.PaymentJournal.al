pageextension 50101 "PMIS Payment Journal" extends "Payment Journal"
{
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
}
