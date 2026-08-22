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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Refund Process Events", OnBeforeCreateItemSalesLine, '', false, false)]
    local procedure "Shpfy Refund Process Events_OnBeforeCreateItemSalesLine"(RefundHeader: Record "Shpfy Refund Header"; RefundLine: Record "Shpfy Refund Line"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var NextLineNo: Integer; var Handled: Boolean)
    var
        Shop: Record "Shpfy Shop";
        ShopLocation: Record "Shpfy Shop Location";
    begin
        if RefundLine."Item No." = '' then
            exit;

        Shop.Get(RefundHeader."Shop Code");

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        if SalesLine.FindLast() then
            NextLineNo := SalesLine."Line No." + 10000
        else
            NextLineNo := 10000;

        SalesLine.Init();
        SalesLine.SetHideValidationDialog(true);

        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("Line No.", NextLineNo);

        SalesLine.Insert(true);

        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", RefundLine."Item No.");

        if RefundLine."Variant Code" <> '' then
            SalesLine.Validate("Variant Code", RefundLine."Variant Code");

        if RefundLine."Unit of Measure Code" <> '' then
            SalesLine.Validate("Unit of Measure Code", RefundLine."Unit of Measure Code");

        if ShopLocation.Get(Shop.Code, RefundLine."Location Id")
        then
            SalesLine.Validate("Location Code", ShopLocation."Default Location Code");

        if (Shop."Return Location Priority" =
            "Shpfy Return Location Priority"::"Default Return Location") or
           (SalesLine."Location Code" = '')
        then
            SalesLine.Validate("Location Code", Shop."Return Location");

        SalesLine.Validate(Quantity, RefundLine.Quantity);

        case Shop."Currency Handling" of
            "Shpfy Currency Handling"::"Shop Currency":
                begin
                    SalesLine.Validate("Unit Price", RefundLine.Amount);

                    SalesLine.Validate("Line Discount Amount", (SalesLine."Unit Price" * SalesLine.Quantity) - RefundLine."Subtotal Amount");
                end;

            "Shpfy Currency Handling"::"Presentment Currency":
                begin
                    SalesLine.Validate("Unit Price", RefundLine."Presentment Amount");

                    SalesLine.Validate("Line Discount Amount", (SalesLine."Unit Price" * SalesLine.Quantity) - RefundLine."Presentment Subtotal Amount");
                end;
        end;

        SalesLine."Shpfy Refund Id" := RefundHeader."Refund Id";
        SalesLine."Shpfy Refund Line Id" := RefundLine."Refund Line Id";

        SalesLine.Modify(true);

        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Refund Process Events", OnAfterProcessSalesDocument, '', false, false)]
    local procedure "Shpfy Refund Process Events_OnAfterProcessSalesDocument"(RefundHeader: Record "Shpfy Refund Header"; var SalesHeader: Record "Sales Header")
    begin
        PMISFunctions.DeleteSalesOrder(RefundHeader);
    end;

    var
        PMISFunctions: Codeunit "PMIS Functions";
}
