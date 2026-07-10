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

    procedure DoCreateItem(var ShopifyProduct: Record "Shpfy Product"; var ShopifyVariant: Record "Shpfy Variant"; var Item: Record Item; ForVariant: Boolean)
    var
        ItemCategory: Record "Item Category";
        ItemVariant: Record "Item Variant";
        Vendor: Record Vendor;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrentTemplateCode: Code[20];
        ItemNo: Code[20];
        Code: Text;
    begin
        if TemplateCode = '' then
            CurrentTemplateCode := FindItemTemplate(ShopifyProduct, ShopifyVariant)
        else
            CurrentTemplateCode := TemplateCode;

        if ShopifyVariant.SKU <> '' then
            case Shop."SKU Mapping" of
                Shop."SKU Mapping"::"Item No.":
                    ItemNo := CopyStr(ShopifyVariant.SKU, 1, MaxStrLen(ItemNo));
                Shop."SKU Mapping"::"Item No. + Variant Code":
                    begin
                        ShopifyVariant.SKU.Split(Shop."SKU Field Separator").Get(1, Code);
                        ItemNo := CopyStr(Code, 1, MaxStrLen(ItemNo));
                    end;
            end;
        Clear(Item."No.");
        Clear(Item."Item Category Code");
        Clear(Item."Base Unit of Measure");
        CreateItemFromTemplate(Item, CurrentTemplateCode, ItemNo);
        Item.Description := ShopifyProduct.Title;

        CreateItemUnitOfMeasure(ShopifyVariant, Item);

        if ShopifyVariant."Unit Cost" <> 0 then
            if Shop."Currency Code" = '' then
                Item.Validate("Unit Cost", ShopifyVariant."Unit Cost")
            else
                Item.Validate("Unit Cost", Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), Shop."Currency Code", ShopifyVariant."Unit Cost", CurrencyExchangeRate.ExchangeRate(WorkDate(), Shop."Currency Code"))));

        if ShopifyVariant.Price <> 0 then
            if Shop."Currency Code" = '' then
                Item.Validate("Unit Price", ShopifyVariant.Price)
            else
                Item.Validate("Unit Price", Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), Shop."Currency Code", ShopifyVariant.Price, CurrencyExchangeRate.ExchangeRate(WorkDate(), Shop."Currency Code"))));

        if ShopifyProduct."Product Type" <> '' then begin
            ItemCategory.SetFilter(Description, CleanFilterValue(ShopifyProduct."Product Type", MaxStrLen(ItemCategory.Description)));
            if ItemCategory.FindFirst() then
                Item."Item Category Code" := ItemCategory.Code;
        end;

        if ShopifyProduct.Vendor <> '' then begin
            Vendor.SetFilter(Name, CleanFilterValue(ShopifyProduct.Vendor, MaxStrLen(Vendor.Name)));
            if Vendor.FindFirst() then
                Item."Vendor No." := Vendor."No.";
        end;

        if Shop."Sync Item Marketing Text" then
            CreateEntityText(ShopifyProduct, Item);

        Item.Modify();
        if ForVariant then begin
            ShopifyVariant."Item SystemId" := Item.SystemId;
            ShopifyVariant.Modify();
        end else begin
            ShopifyProduct."Item SystemId" := Item.SystemId;
            ShopifyProduct.Modify();
        end;

        Clear(ItemVariant);
        CreateReferences(ShopifyProduct, ShopifyVariant, Item, ItemVariant);
    end;

    procedure FindItemTemplate(ShopifyProduct: Record "Shpfy Product"; ShopifyVariant: Record "Shpfy Variant") Result: Code[20]
    var
        IsHandled: Boolean;
    begin
        Shop.TestField("Item Templ. Code");
        Result := Shop."Item Templ. Code";
        exit(Result);
    end;

    procedure CreateItemFromTemplate(var Item: Record Item; ItemTemplCode: Code[20]; ItemNo: Code[20])
    var
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        if not ItemTempl.Get(ItemTemplCode) then
            exit;

        if ItemNo <> '' then
            Item."No." := ItemNo
        else
            ItemTemplMgt.InitItemNo(Item, ItemTempl);

        Item.Insert(true);
        ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl, true);
    end;

    procedure CreateItemUnitOfMeasure(ShopifyVariant: Record "Shpfy Variant"; Item: Record Item)
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
        Code: Text;
    begin
        case ShopifyVariant."UoM Option Id" of
            1:
                Code := ShopifyVariant."Option 1 Value";
            2:
                Code := ShopifyVariant."Option 2 Value";
            3:
                Code := ShopifyVariant."Option 3 Value";
        end;
        if Code <> '' then begin
            Code := FindUoMCode(ShopifyVariant);
            if Code <> '' then begin
                ItemUnitofMeasure.SetRange("Item No.", Item."No.");
                ItemUnitofMeasure.SetRange(Code, Code);
                if ItemUnitofMeasure.IsEmpty() then begin
                    Clear(ItemUnitofMeasure);
                    ItemUnitofMeasure."Item No." := Item."No.";
                    ItemUnitofMeasure.Code := CopyStr(Code, 1, MaxStrLen(ItemUnitofMeasure.Code));
                    ItemUnitofMeasure."Qty. per Unit of Measure" := 1;
                    ItemUnitofMeasure.Insert();
                end;
            end;
        end;
    end;

    procedure FindUoMCode(ShopifyVariant: Record "Shpfy Variant"): Code[10]
    var
        UnitofMeasure: Record "Unit of Measure";
        Code: Text;
    begin
        case ShopifyVariant."UoM Option Id" of
            1:
                Code := ShopifyVariant."Option 1 Value";
            2:
                Code := ShopifyVariant."Option 2 Value";
            3:
                Code := ShopifyVariant."Option 3 Value";
        end;
        if Code <> '' then
            if UnitofMeasure.Get(CopyStr(Code.ToUpper(), 1, MaxStrLen(UnitofMeasure.Code))) then
                exit(UnitofMeasure.Code)
            else begin
                UnitofMeasure.SetFilter(Description, '@' + Code);
                if UnitofMeasure.IsEmpty then begin
#pragma warning disable AA0139
                    if (StrLen(Code) <= MaxStrLen(UnitofMeasure.Code)) then begin
                        Clear(UnitofMeasure);
                        UnitofMeasure.Code := Code;
                        UnitofMeasure.Description := Code;
                        UnitofMeasure.Insert();
                        exit(UnitofMeasure.Code);
                    end;
#pragma warning restore AA0139
                end else begin
                    UnitofMeasure.FindFirst();
                    exit(UnitofMeasure.Code);
                end;
            end;
    end;

    procedure CreateEntityText(ShopifyProduct: Record "Shpfy Product"; Item: Record Item)
    var
        EntityTextRec: Record "Entity Text";
        EntityText: Codeunit "Entity Text";
    begin
        if not ShopifyProduct."Description as HTML".HasValue() then
            exit;

        EntityTextRec.Company := CopyStr(CompanyName(), 1, MaxStrLen(EntityTextRec.Company));
        EntityTextRec."Source Table Id" := Database::Item;
        EntityTextRec."Source System Id" := Item.SystemId;
        EntityTextRec.Scenario := "Entity Text Scenario"::"Marketing Text";
        EntityTextRec.Insert();

        EntityText.UpdateText(EntityTextRec, GetDescriptionHtml(ShopifyProduct));
        EntityTextRec.Modify();
    end;

    procedure GetDescriptionHtml(var ShopifyProduct: Record "Shpfy Product"): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        ShopifyProduct.CalcFields("Description as HTML");
        ShopifyProduct."Description as HTML".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure CreateReferences(ShopifyProduct: Record "Shpfy Product"; ShopifyVariant: Record "Shpfy Variant"; Item: Record Item; ItemVariant: Record "Item Variant")
    begin
        if ShopifyVariant.Barcode <> '' then
            CreateItemBarCode(Item."No.", ItemVariant.Code, FindUoMCode(ShopifyVariant), ShopifyVariant.Barcode);
        if ShopifyVariant.SKU <> '' then
            case Shop."SKU Mapping" of
                Shop."SKU Mapping"::"Bar Code":
                    CreateItemBarCode(Item."No.", ItemVariant.Code, FindUoMCode(ShopifyVariant), ShopifyVariant.SKU);
                Shop."SKU Mapping"::"Vendor Item No.":
                    if Item."Vendor No." <> '' then begin
                        if ItemVariant.code = '' then begin
                            Item."Vendor Item No." := ShopifyVariant.SKU;
                            Item.Modify();
                        end;
                        CreateItemReference(Item."No.", ItemVariant.Code, FindUoMCode(ShopifyVariant), "Item Reference Type"::Vendor, Item."Vendor No.", ShopifyVariant.SKU);
                    end;
            end;
    end;

    procedure CreateItemBarCode(ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasure: Code[10]; BarCode: Text)
    begin
        CreateItemReference(ItemNo, VariantCode, UnitOfMeasure, "Item Reference Type"::"Bar Code", '', CopyStr(Barcode, 1, 50));
    end;

    procedure CreateItemReference(ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasure: Code[10]; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[20]; ReferenceNo: Code[50])
    var
        ItemReference: Record "Item Reference";
    begin
        Clear(ItemReference);
        ItemReference."Item No." := ItemNo;
        ItemReference."Variant Code" := VariantCode;
        ItemReference."Unit of Measure" := UnitOfMeasure;
        ItemReference."Reference Type" := ReferenceType;
        ItemReference."Reference Type No." := ReferenceTypeNo;
        ItemReference."Reference No." := ReferenceNo;
        if not ItemReference.Insert() then
            ItemReference.Modify();

        if VariantCode <> '' then begin
            ItemReference.SetRange("Item No.", ItemNo);
            ItemReference.SetRange("Variant Code", '');
            ItemReference.SetRange("Unit of Measure", UnitOfMeasure);
            ItemReference.SetRange("Reference Type", ReferenceType);
            ItemReference.SetRange("Reference Type No.", ReferenceTypeNo);
            ItemReference.SetRange("Reference No.", ReferenceNo);
            if not ItemReference.IsEmpty then
                ItemReference.DeleteAll();
        end;
    end;

    procedure CleanFilterValue(Value: Text): Text;
    begin
        exit('@' + Value.Replace('(', '?').Replace(')', '?').Replace('*', '?').Replace('.', '?').Replace('<', '?').Replace('>', '?').Replace('=', '?'));
    end;

    procedure CleanFilterValue(Value: Text; MaxLength: Integer): Text;
    begin
        exit(CleanFilterValue(CopyStr(Value, 1, MaxLength)));
    end;

    procedure SetShop(ShopifyShop: Record "Shpfy Shop")
    begin
        Shop := ShopifyShop;
        TemplateCode := Shop."Item Templ. Code";
    end;
}
