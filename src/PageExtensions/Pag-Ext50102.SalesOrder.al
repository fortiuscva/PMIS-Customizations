pageextension 50102 "PMIS Sales Order" extends "Sales Order"
{
    actions
    {
        addlast(Processing)
        {
            action("PMIS Create Special Order")
            {
                ApplicationArea = All;
                Caption = 'Create Special Order';
                Image = CreateDocument;
                ToolTip = 'Create special order requisition worksheet lines for this sales order.';

                trigger OnAction()
                var
                    SalesLine: Record "Sales Line";
                    ReqLine: Record "Requisition Line";
                    GetSalesOrders: Report "Get Sales Orders";
                begin
                    // Filter sales lines for the current sales order
                    SalesLine.SetRange("Document Type", Rec."Document Type");
                    SalesLine.SetRange("Document No.", Rec."No.");
                    SalesLine.SetRange("Purchasing Code", 'SPECIAL');

                    if SalesLine.IsEmpty() then
                        Error(
                            'No sales lines with Purchasing Code SPECIAL were found for Sales Order %1.',
                            Rec."No.");

                    // Set the destination requisition worksheet batch
                    ReqLine.Init();
                    ReqLine."Worksheet Template Name" := 'REQ';
                    ReqLine."Journal Batch Name" := 'DEFAULT';

                    // Pass the requisition worksheet context and special order indicator
                    GetSalesOrders.SetReqWkshLine(ReqLine, 1);

                    // Pass the filtered sales lines to standard Report 698
                    GetSalesOrders.SetTableView(SalesLine);
                    GetSalesOrders.UseRequestPage(true);
                    GetSalesOrders.RunModal();
                end;
            }
        }
    }
}