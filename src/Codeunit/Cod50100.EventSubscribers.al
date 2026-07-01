codeunit 50100 "PMIS Event Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnBeforeCreateItemSalesLine, '', false, false)]
    local procedure "Shpfy Order Events_OnBeforeCreateItemSalesLine"(ShopifyOrderHeader: Record "Shpfy Order Header"; ShopifyOrderLine: Record "Shpfy Order Line"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var Handled: Boolean)
    var
        Item: Record Item;
        Shop: Record "Shpfy Shop";
    begin
        if ShopifyOrderLine."Item No." = '' then
            exit;

        if Item.Get(ShopifyOrderLine."Item No.") then
            exit;

        Shop.Get(ShopifyOrderHeader."Shop Code");
        CreateItemFromTemplate(Item, Shop."Item Templ. Code", ShopifyOrderLine."Item No.", ShopifyOrderLine.Description);
    end;

    procedure CreateItemFromTemplate(var Item: Record Item; ItemTemplCode: Code[20]; ItemNo: Code[20]; ItemDescription: Text)
    var
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        if not ItemTempl.Get(ItemTemplCode) then
            exit;

        Item.Init();
        Item."No." := ItemNo;
        Item.Insert(true);

        ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl, true);

        Item.Description := CopyStr(ItemDescription, 1,
                MaxStrLen(Item.Description));

        Item.Modify(true);

    end;

}
