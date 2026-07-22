codeunit 50100 "PMIS Event Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnBeforeCreateItemSalesLine, '', false, false)]
    local procedure "Shpfy Order Events_OnBeforeCreateItemSalesLine"(ShopifyOrderHeader: Record "Shpfy Order Header"; ShopifyOrderLine: Record "Shpfy Order Line"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var Handled: Boolean)
    var
        Item: Record Item;
        ShopifyShop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
    begin
        if ShopifyOrderLine."Item No." = '' then
            exit;

        if Item.Get(ShopifyOrderLine."Item No.") then
            exit;

        if not ShopifyVariant.Get(ShopifyOrderLine."Shopify Variant Id") then
            exit;

        if not ShopifyProduct.Get(ShopifyVariant."Product Id") then
            exit;
        ShopifyShop.Get(ShopifyOrderHeader."Shop Code");
        PMISFunctions.SetShop(ShopifyShop);
        PMISFunctions.DoCreateItem(ShopifyProduct, ShopifyVariant, Item, true);
    end;

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

    var
        PMISFunctions: Codeunit "PMIS Functions";
}
