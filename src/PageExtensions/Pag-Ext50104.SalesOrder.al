pageextension 50104 "PMIS Sales Order" extends "Sales Order"
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
                    ReqWkshTemplate: Record "Req. Wksh. Template";
                    ReqLine: Record "Requisition Line";
                    ReqWkshName: Record "Requisition Wksh. Name";
                    ReqWkshTemplateList: Page "Req. Worksheet Template List";
                    ReqWkshNames: Page "Req. Wksh. Names";
                    GetSalesOrders: Report "Get Sales Orders";
                begin
                    SalesLine.SetRange("Document Type", Rec."Document Type");
                    SalesLine.SetRange("Document No.", Rec."No.");

                    ReqWkshTemplate.SetRange(
                        Type,
                        ReqWkshTemplate.Type::"Req.");
                    ReqWkshTemplateList.SetTableView(ReqWkshTemplate);
                    ReqWkshTemplateList.LookupMode(true);
                    if ReqWkshTemplateList.RunModal() <> Action::LookupOK then
                        exit;
                    ReqWkshTemplateList.GetRecord(ReqWkshTemplate);

                    ReqWkshName.FilterGroup(2);
                    ReqWkshName.SetRange(
                        "Worksheet Template Name",
                        ReqWkshTemplate.Name);
                    ReqWkshName.FilterGroup(0);
                    ReqWkshNames.SetTableView(ReqWkshName);
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
