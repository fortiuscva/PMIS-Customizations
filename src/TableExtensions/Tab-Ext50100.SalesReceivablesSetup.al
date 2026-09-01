tableextension 50100 "PMIS Sales & Receivables Setup" extends "Sales & Receivables Setup"
{
    fields
    {
        field(50100; "PMIS Default Custom Item"; Code[20])
        {
            Caption = 'Default Custom Item';
            DataClassification = CustomerContent;
            TableRelation = Item."No." where(Type = const("Non-Inventory"));
        }
    }
}
