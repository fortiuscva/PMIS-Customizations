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

    var
        PMISFunctions: Codeunit "PMIS Functions";
}
