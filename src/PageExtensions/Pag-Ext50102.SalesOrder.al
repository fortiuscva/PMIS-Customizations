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
                Ellipsis = true;

                trigger OnAction()
                var
                    SalesLine: Record "Sales Line";
                    Purchasing: Record Purchasing;
                    ReqLine: Record "Requisition Line";
                    ReqWkshName: Record "Requisition Wksh. Name";
                    ReqWkshNames: Page "Req. Wksh. Names";
                    GetSalesOrders: Report "Get Sales Orders";
                    SpecialOrderPurchasingCode: Code[10];
                begin
                    SalesLine.SetRange("Document Type", Rec."Document Type");
                    SalesLine.SetRange("Document No.", Rec."No.");

                    if SalesLine.FindSet() then
                        repeat
                            if (SpecialOrderPurchasingCode = '') and
                               (SalesLine."Purchasing Code" <> '') and
                               Purchasing.Get(SalesLine."Purchasing Code") and
                               Purchasing."Special Order"
                            then
                                SpecialOrderPurchasingCode := SalesLine."Purchasing Code";
                        until SalesLine.Next() = 0;

                    if SpecialOrderPurchasingCode = '' then
                        Error(
                            'No sales lines with a Purchasing Code configured for Special Order were found for Sales Order %1.',
                            Rec."No.");

                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", Rec."Document Type");
                    SalesLine.SetRange("Document No.", Rec."No.");
                    SalesLine.SetRange("Purchasing Code", SpecialOrderPurchasingCode);

                    ReqWkshNames.LookupMode(true);
                    if ReqWkshNames.RunModal() <> Action::LookupOK then
                        exit;
                    ReqWkshNames.GetRecord(ReqWkshName);

                    ReqLine.Init();
                    ReqLine."Worksheet Template Name" :=
                        ReqWkshName."Worksheet Template Name";
                    ReqLine."Journal Batch Name" := ReqWkshName.Name;

                    GetSalesOrders.SetReqWkshLine(ReqLine, 1);
                    GetSalesOrders.SetTableView(SalesLine);
                    GetSalesOrders.UseRequestPage(true);
                    GetSalesOrders.RunModal();
                end;
            }
        }
    }
}