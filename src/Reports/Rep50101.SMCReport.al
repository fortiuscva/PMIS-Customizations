report 50101 "PMIS SMC Report"
{
    ApplicationArea = All;
    Caption = 'SMC Report';
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = true;

    trigger OnPreReport()
    begin
        ExcelBuffer.DeleteAll();
        AddColumnHeaders();
    end;

    trigger OnPostReport()
    begin
        ExportSalesInvoices();
        ExportSalesCreditMemos();

        if DataRowCount = 0 then
            Error('No eligible SMC transactions found.');

        ExcelBuffer.CreateNewBook('SMC Report');
        ExcelBuffer.WriteSheet('SMC Report', CompanyName(), UserId());
        ExcelBuffer.CloseBook();
        ExcelBuffer.SetFriendlyFilename('SMC_Report.xlsx');
        ExcelBuffer.OpenExcel();
    end;

    local procedure AddColumnHeaders()
    begin
        ExcelBuffer.NewRow();
        AddTextColumn('SMC Account Number');
        AddTextColumn('Distributor Branch Code');
        AddTextColumn('Customer Number');
        AddTextColumn('Customer Name');
        AddTextColumn('Street Address');
        AddTextColumn('Customer Shipped City');
        AddTextColumn('Customer Shipped State');
        AddTextColumn('Customer Shipped Zip');
        AddTextColumn('Invoice Number');
        AddTextColumn('Invoice Date');
        AddTextColumn('Part Number');
        AddTextColumn('Quantity');
        AddTextColumn('UOM');
        AddTextColumn('Unit Price to End User');
        AddTextColumn('Agreement Number');
    end;

    local procedure ExportSalesInvoices()
    begin
        SalesInvoiceHeader.Reset();
        if SalesInvoiceHeader.FindSet() then
            repeat
                SalesInvoiceLine.Reset();
                SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
                SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);

                if SalesInvoiceLine.FindSet() then
                    repeat
                        WriteInvoiceLine(SalesInvoiceHeader, SalesInvoiceLine);
                    until SalesInvoiceLine.Next() = 0;
            until SalesInvoiceHeader.Next() = 0;
    end;

    local procedure ExportSalesCreditMemos()
    begin
        SalesCrMemoHeader.Reset();
        if SalesCrMemoHeader.FindSet() then
            repeat
                SalesCrMemoLine.Reset();
                SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
                SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);

                if SalesCrMemoLine.FindSet() then
                    repeat
                        WriteCreditMemoLine(SalesCrMemoHeader, SalesCrMemoLine);
                    until SalesCrMemoLine.Next() = 0;
            until SalesCrMemoHeader.Next() = 0;
    end;

    local procedure WriteInvoiceLine(InvoiceHeader: Record "Sales Invoice Header";
        InvoiceLine: Record "Sales Invoice Line")
    var
        UnitPrice: Decimal;
    begin
        if InvoiceLine.Type <> InvoiceLine.Type::Item then
            exit;
        if InvoiceLine.Quantity = 0 then
            exit;

        UnitPrice := InvoiceLine."Unit Price";

        ExcelBuffer.NewRow();

        AddTextColumn(GetSMCAccountNumber(InvoiceLine."No."));
        AddTextColumn('YAK');
        AddTextColumn(InvoiceHeader."Sell-to Customer No.");
        AddTextColumn(InvoiceHeader."Sell-to Customer Name");
        AddTextColumn(InvoiceHeader."Ship-to Address");
        AddTextColumn(InvoiceHeader."Ship-to City");
        AddTextColumn(InvoiceHeader."Ship-to County");
        AddTextColumn(InvoiceHeader."Ship-to Post Code");
        AddTextColumn(InvoiceHeader."No.");
        AddTextColumn(FormatDocumentDate(InvoiceHeader."Document Date"));
        AddTextColumn(InvoiceLine."No.");
        AddTextColumn(Format(Abs(InvoiceLine.Quantity), 0, 9));
        AddTextColumn(InvoiceLine."Unit of Measure Code");
        AddTextColumn(Format(UnitPrice, 0, '<Precision,2:2><Standard Format,0>'));
        AddTextColumn('0');

        DataRowCount += 1;
    end;


    local procedure WriteCreditMemoLine(CreditMemoHeader: Record "Sales Cr.Memo Header"; CreditMemoLine: Record "Sales Cr.Memo Line")
    var
        UnitPrice: Decimal;
    begin
        if CreditMemoLine.Quantity = 0 then
            exit;

        UnitPrice := CreditMemoLine."Unit Price";

        ExcelBuffer.NewRow();

        AddTextColumn(GetSMCAccountNumber(CreditMemoLine."No."));
        AddTextColumn('YAK');
        AddTextColumn(CreditMemoHeader."Sell-to Customer No.");
        AddTextColumn(CreditMemoHeader."Sell-to Customer Name");
        AddTextColumn(CreditMemoHeader."Ship-to Address");
        AddTextColumn(CreditMemoHeader."Ship-to City");
        AddTextColumn(CreditMemoHeader."Ship-to County");
        AddTextColumn(CreditMemoHeader."Ship-to Post Code");
        AddTextColumn(CreditMemoHeader."No.");
        AddTextColumn(FormatDocumentDate(CreditMemoHeader."Document Date"));
        AddTextColumn(CreditMemoLine."No.");
        AddTextColumn(Format(Abs(CreditMemoLine.Quantity), 0, 9));
        AddTextColumn(CreditMemoLine."Unit of Measure Code");
        AddTextColumn(Format(UnitPrice, 0, '<Precision,2:2><Standard Format,0>'));
        AddTextColumn('0');

        DataRowCount += 1;
    end;


    local procedure FormatDocumentDate(DocumentDate: Date): Text
    begin
        if DocumentDate = 0D then
            exit('');

        exit(Format(DocumentDate, 0, '<Year4><Month,2><Day,2>'));
    end;


    local procedure CalculateUnitPrice(
        LineAmount: Decimal;
        LineQuantity: Decimal): Decimal
    begin
        if LineQuantity = 0 then
            exit(0);

        exit(Round(Abs(LineAmount) / Abs(LineQuantity), 0.01));
    end;


    local procedure GetSMCAccountNumber(ItemNo: Code[20]): Text

    var
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        if Item.Get(ItemNo) then
            if Item."Vendor No." <> '' then
                if Vendor.Get(Item."Vendor No.") then
                    if Vendor."Our Account No." <> '' then
                        exit(Vendor."Our Account No.");
        exit('');
    end;


    local procedure AddTextColumn(ColumnValue: Text)
    begin
        ExcelBuffer.AddColumn(
            ColumnValue,
            false,
            '',
            false,
            false,
            false,
            '',
            ExcelBuffer."Cell Type"::Text);
    end;

    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DataRowCount: Integer;
}