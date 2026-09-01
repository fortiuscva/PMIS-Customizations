pageextension 50100 "PMIS Sales & Receivables Setup" extends "Sales & Receivables Setup"
{
    layout
    {
        addlast(General)
        {

            field("PMIS Default Custom Item"; Rec."PMIS Default Custom Item")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Default Custom Item field.', Comment = '%';
            }
        }
    }
}
