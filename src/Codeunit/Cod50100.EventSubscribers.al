codeunit 50100 "PMIS Event Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", 'OnAfterCreateItemSalesLine', '', false, false)]
    local procedure AddTaxLineToSalesOrder(ShopifyOrderHeader: Record "Shpfy Order Header"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        SalesLineRec: Record "Sales Line";
        TaxSetup: Record "Tax Setup";
        GLAccount: Record "G/L Account";
    begin

        SalesLineRec.Reset();
        SalesLineRec.SetRange("Document No.", SalesHeader."No.");
        SalesLineRec.SetRange(Type, SalesLineRec.Type::"G/L Account");
        if TaxSetup.Get() then
            SalesLineRec.SetRange("No.", TaxSetup."Tax Account (Sales)");
        if SalesLineRec.FindFirst() then
            exit;

        if (TaxSetup.Get()) and (GLAccount.Get(TaxSetup."Tax Account (Sales)")) and (ShopifyOrderHeader."VAT Amount" <> 0) then begin
            SalesLineRec.Init();
            SalesLineRec.Validate("Document Type", SalesHeader."Document Type");
            SalesLineRec.Validate("Document No.", SalesHeader."No.");
            SalesLineRec.Validate("Line No.", SalesLine."Line No." + 10000);
            SalesLineRec.Validate(Type, SalesLine.Type::"G/L Account");
            SalesLineRec.Validate("No.", GLAccount."No.");
            SalesLineRec.Validate(Description, 'Shopify Sales Tax');
            SalesLineRec.Validate(Quantity, 1);
            SalesLineRec.Validate("Unit Price", ShopifyOrderHeader."VAT Amount");
            SalesLineRec.Validate(Amount, ShopifyOrderHeader."VAT Amount");
            SalesLineRec.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", 'OnAfterCreateSalesHeader', '', false, false)]
    local procedure OnAfterCreateSalesHeader(var SalesHeader: Record "Sales Header"; OrderHeader: Record "Shpfy Order Header")
    var
        ShopifyShop: Record "Shpfy Shop";
    begin
        ShopifyShop.Get(OrderHeader."Shop Code");
        if SalesHeader."Ship-to Phone No." = '' then begin
            SalesHeader.Validate("Ship-to Phone No.", SalesHeader."Sell-to Phone No.");
            SalesHeader.Modify();
        end;
    end;
}
