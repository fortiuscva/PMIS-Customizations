
report 50101 "PMIS SMC Report"
{
    ApplicationArea = All;
    Caption = 'SMC Report';
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Filters)
                {
                    Caption = 'Filters';

                    field(FromDate; FromDate)
                    {
                        ApplicationArea = All;
                        Caption = 'From Date';
                        ToolTip = 'Specifies the starting document date.';
                    }

                    field(ToDate; ToDate)
                    {
                        ApplicationArea = All;
                        Caption = 'To Date';
                        ToolTip = 'Specifies the ending document date.';
                    }

                    field(VendorNoFilter; VendorNoFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Vendor Filter';
                        TableRelation = Vendor."No.";
                        ToolTip = 'Enter one or more vendor numbers separated by |. Example: 2010|2020.';
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        if (FromDate <> 0D) and (ToDate <> 0D) then
            if FromDate > ToDate then
                Error('From Date cannot be later than To Date.');

        ExcelBuffer.DeleteAll();
        DataRowCount := 0;

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

    // Add Excel column headers
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

    // Export Posted Sales Invoices
    local procedure ExportSalesInvoices()
    begin
        SalesInvoiceHeader.Reset();
        ApplyInvoiceDateFilter();

        if SalesInvoiceHeader.FindSet() then
            repeat
                SalesInvoiceLine.Reset();
                SalesInvoiceLine.SetRange(
                    "Document No.",
                    SalesInvoiceHeader."No.");
                SalesInvoiceLine.SetRange(
                    Type,
                    SalesInvoiceLine.Type::Item);

                if SalesInvoiceLine.FindSet() then
                    repeat
                        WriteInvoiceLine(
                            SalesInvoiceHeader,
                            SalesInvoiceLine);
                    until SalesInvoiceLine.Next() = 0;

            until SalesInvoiceHeader.Next() = 0;
    end;

    // Export Posted Sales Credit Memos
    local procedure ExportSalesCreditMemos()
    begin
        SalesCrMemoHeader.Reset();
        ApplyCreditMemoDateFilter();

        if SalesCrMemoHeader.FindSet() then
            repeat
                SalesCrMemoLine.Reset();
                SalesCrMemoLine.SetRange(
                    "Document No.",
                    SalesCrMemoHeader."No.");
                SalesCrMemoLine.SetRange(
                    Type,
                    SalesCrMemoLine.Type::Item);

                if SalesCrMemoLine.FindSet() then
                    repeat
                        WriteCreditMemoLine(
                            SalesCrMemoHeader,
                            SalesCrMemoLine);
                    until SalesCrMemoLine.Next() = 0;

            until SalesCrMemoHeader.Next() = 0;
    end;

    // Apply date filter to Sales Invoice Header
    local procedure ApplyInvoiceDateFilter()
    begin
        if (FromDate <> 0D) and (ToDate <> 0D) then
            SalesInvoiceHeader.SetRange(
                "Document Date",
                FromDate,
                ToDate)
        else
            if FromDate <> 0D then
                SalesInvoiceHeader.SetFilter(
                    "Document Date",
                    '>=%1',
                    FromDate)
            else
                if ToDate <> 0D then
                    SalesInvoiceHeader.SetFilter(
                        "Document Date",
                        '<=%1',
                        ToDate);
    end;

    // Apply date filter to Sales Credit Memo Header
    local procedure ApplyCreditMemoDateFilter()
    begin
        if (FromDate <> 0D) and (ToDate <> 0D) then
            SalesCrMemoHeader.SetRange(
                "Document Date",
                FromDate,
                ToDate)
        else
            if FromDate <> 0D then
                SalesCrMemoHeader.SetFilter(
                    "Document Date",
                    '>=%1',
                    FromDate)
            else
                if ToDate <> 0D then
                    SalesCrMemoHeader.SetFilter(
                        "Document Date",
                        '<=%1',
                        ToDate);
    end;

    // Write eligible Sales Invoice line to Excel
    local procedure WriteInvoiceLine(
        InvoiceHeader: Record "Sales Invoice Header";
        InvoiceLine: Record "Sales Invoice Line")
    var
        SMCAccountNo: Text;
        UnitPrice: Decimal;
    begin
        if InvoiceLine.Quantity = 0 then
            exit;

        if not IsEligibleItem(InvoiceLine."No.", SMCAccountNo) then
            exit;

        UnitPrice := InvoiceLine."Unit Price";

        ExcelBuffer.NewRow();

        AddTextColumn(SMCAccountNo);
        AddTextColumn('YAK');
        AddTextColumn(InvoiceHeader."Sell-to Customer No.");
        AddTextColumn(InvoiceHeader."Sell-to Customer Name");
        AddTextColumn(InvoiceHeader."Ship-to Address");
        AddTextColumn(InvoiceHeader."Ship-to City");
        AddTextColumn(InvoiceHeader."Ship-to County");
        AddTextColumn(InvoiceHeader."Ship-to Post Code");
        AddTextColumn(InvoiceHeader."No.");
        AddTextColumn(
            FormatDocumentDate(InvoiceHeader."Document Date"));
        AddTextColumn(InvoiceLine."No.");
        AddTextColumn(Format(Abs(InvoiceLine.Quantity), 0, 9));
        AddTextColumn('EA');
        AddTextColumn(
            Format(UnitPrice, 0, '<Precision,2:2><Standard Format,0>'));
        AddTextColumn('0');

        DataRowCount += 1;
    end;

    // Write eligible Sales Credit Memo line to Excel
    local procedure WriteCreditMemoLine(
        CreditMemoHeader: Record "Sales Cr.Memo Header";
        CreditMemoLine: Record "Sales Cr.Memo Line")
    var
        SMCAccountNo: Text;
        UnitPrice: Decimal;
    begin
        if CreditMemoLine.Quantity = 0 then
            exit;

        if not IsEligibleItem(CreditMemoLine."No.", SMCAccountNo) then
            exit;

        UnitPrice := CreditMemoLine."Unit Price";

        ExcelBuffer.NewRow();

        AddTextColumn(SMCAccountNo);
        AddTextColumn('YAK');
        AddTextColumn(CreditMemoHeader."Sell-to Customer No.");
        AddTextColumn(CreditMemoHeader."Sell-to Customer Name");
        AddTextColumn(CreditMemoHeader."Ship-to Address");
        AddTextColumn(CreditMemoHeader."Ship-to City");
        AddTextColumn(CreditMemoHeader."Ship-to County");
        AddTextColumn(CreditMemoHeader."Ship-to Post Code");
        AddTextColumn(CreditMemoHeader."No.");
        AddTextColumn(
            FormatDocumentDate(CreditMemoHeader."Document Date"));
        AddTextColumn(CreditMemoLine."No.");
        AddTextColumn(Format(Abs(CreditMemoLine.Quantity), 0, 9));
        AddTextColumn('EA');
        AddTextColumn(
            Format(UnitPrice, 0, '<Precision,2:2><Standard Format,0>'));
        AddTextColumn('0');

        DataRowCount += 1;
    end;

    // Check Item Vendor No. and retrieve SMC Account Number
    local procedure IsEligibleItem(
        ItemNo: Code[20];
        var SMCAccountNo: Text): Boolean
    var
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        Clear(SMCAccountNo);

        // Filter Item by the posted sales line Item No.
        Item.SetRange("No.", ItemNo);

        // Apply selected Vendor filter.
        // Supports 2010, 2010|2020, 2010|2020|3050, etc.
        if VendorNoFilter <> '' then
            Item.SetFilter("Vendor No.", VendorNoFilter);

        // Retrieve only the Item matching both filters.
        if not Item.FindFirst() then
            exit(false);

        // Validate Item Vendor No.
        if Item."Vendor No." = '' then
            exit(false);

        // Retrieve Vendor record.
        if not Vendor.Get(Item."Vendor No.") then
            exit(false);

        // Include only items with an SMC Account Number.
        if Vendor."Our Account No." = '' then
            exit(false);

        SMCAccountNo := Vendor."Our Account No.";

        exit(true);
    end;

    // Format Document Date as YYYYMMDD
    local procedure FormatDocumentDate(DocumentDate: Date): Text
    begin
        if DocumentDate = 0D then
            exit('');

        exit(Format(DocumentDate, 0, '<Year4><Month,2><Day,2>'));
    end;

    // Add Excel text column
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
        FromDate: Date;
        ToDate: Date;
        VendorNoFilter: Text;
}
