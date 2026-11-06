pageextension 50102 "Purchase Order Ext" extends "Purchase Order"
{
    layout
    {
        modify("Invoice Received Date")
        {
            ShowMandatory = true;
        }
    }
}
