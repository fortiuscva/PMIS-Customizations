pageextension 50103 "PMIS Item List" extends "Item List"
{
    layout
    {

        addlast(Control1)
        {
            field("PMIS Qty. on Purch. Order"; Rec."Qty. on Purch. Order")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Qty. on Purch. Order field.', Comment = '%';
            }
            field("PMIS Qty. on Sales Order"; Rec."Qty. on Sales Order")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Qty. on Sales Order field.', Comment = '%';
            }
            field("PMIS Qty. on Assembly Order"; Rec."Qty. on Assembly Order")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Qty. on Assembly Order field.', Comment = '%';
            }
        }
    }
    var
        itemcard: page "Item Card";
}
