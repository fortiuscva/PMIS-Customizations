codeunit 50101 "PMIS Functions"
{
    Permissions =
        tabledata Item = rim,
        tabledata "Item Category" = rim,
        tabledata "Item Reference" = rim,
        tabledata "Item Unit of Measure" = rim,
        tabledata "Item Variant" = rim,
        tabledata "Item Vendor" = rim,
        tabledata "Unit of Measure" = rim,
        tabledata Vendor = rim;
    TableNo = "Shpfy Variant";

    var
        Shop: Record "Shpfy Shop";
        ProductEvents: Codeunit "Shpfy Product Events";
        TemplateCode: Code[20];

    procedure DeleteSalesOrder(RefundHeader: Record "Shpfy Refund Header")
    var
        ShopifyOrder: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        if not ShopifyOrder.Get(RefundHeader."Order Id") then
            exit;

        if not FindSalesOrder(ShopifyOrder, SalesHeader) then
            exit;
        if SalesHeader.Status = SalesHeader.Status::Released then
            SalesHeader.PerformManualReopen(SalesHeader);
        if IsExistPostedDocuments(SalesHeader) then
            exit;

        if (ShopifyOrder."Financial Status" = ShopifyOrder."Financial Status"::Refunded) and (ShopifyOrder."Fulfillment Status" = ShopifyOrder."Fulfillment Status"::Unfulfilled) then begin
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");

            if SalesLine.FindSet() then
                repeat
                    SalesLine.Delete(true);
                until SalesLine.Next() = 0;

            SalesHeader.Delete(true);
        end;

    end;

    procedure FindSalesOrder(ShopifyOrder: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header"): Boolean
    begin
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Shpfy Order No.", ShopifyOrder."Shopify Order No.");
        SalesHeader.SetRange("No.", ShopifyOrder."Sales Order No.");
        exit(SalesHeader.FindFirst());
    end;

    procedure IsExistPostedDocuments(SalesHeader: Record "Sales Header"): Boolean
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesShipmentLine.Reset();
        SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");

        if not SalesShipmentLine.IsEmpty() then
            exit(true);

        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange("Order No.", SalesHeader."No.");

        if not SalesInvoiceLine.IsEmpty() then
            exit(true);

        exit(false);
    end;
}
