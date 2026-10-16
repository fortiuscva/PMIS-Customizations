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

        // if (ShopifyOrder.Closed) and (ShopifyOrder."Fulfillment Status" = ShopifyOrder."Fulfillment Status"::Unfulfilled) then begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        if SalesLine.FindSet() then
            repeat
                SalesLine.Delete(true);
            until SalesLine.Next() = 0;

        SalesHeader.Delete(true);

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

    procedure DeleteCancelledSalesOrder(ShopifyOrderHeader: Record "Shpfy Order Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        if ShopifyOrderHeader."Cancelled At" = 0DT then
            exit;

        if ShopifyOrderHeader."Sales Order No." = '' then
            exit;

        if not SalesHeader.Get(SalesHeader."Document Type"::Order, ShopifyOrderHeader."Sales Order No.")
        then
            exit;

        if HasPostedShipmentOrInvoice(SalesHeader) then
            exit;

        // Delete the unposted Sales Order.
        SalesHeader.Delete(true);
    end;

    local procedure HasPostedShipmentOrInvoice(SalesHeader: Record "Sales Header"): Boolean
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        if not SalesShipmentHeader.IsEmpty() then
            exit(true);

        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        if not SalesInvoiceHeader.IsEmpty() then
            exit(true);

        SalesCrMemoHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        if not SalesCrMemoHeader.IsEmpty() then
            exit(true);

        exit(false);
    end;
}
