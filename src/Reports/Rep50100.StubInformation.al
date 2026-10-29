report 50100 "PMIS Stub Information"
{
    Caption = 'PMIS Stub Information';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = StubInformationLayout;

    dataset
    {
        dataitem(PaymentLine; "Gen. Journal Line")
        {
            DataItemTableView = sorting(
                "Journal Template Name",
                "Journal Batch Name",
                "Line No.");

            column(CompanyName; CompanyInfo.Name) { }
            column(RunDate; Today) { }
            column(RunTime; Time) { }
            column(ReportTitle; ReportTitleLbl) { }

            column(JournalTemplate; PaymentLine."Journal Template Name") { }
            column(JournalBatch; PaymentLine."Journal Batch Name") { }
            column(JournalLineNo; PaymentLine."Line No.") { }

            column(VendorNo; Vendor."No.") { }
            column(VendorName; Vendor.Name) { }
            column(VendorReference; Vendor."Our Account No.") { }

            column(CheckNo; PaymentLine."Document No.") { }
            column(CheckDate; PaymentLine."Posting Date") { }
            column(CurrencyCode; PaymentLine."Currency Code") { }
            column(CheckAmount; PaymentLine.Amount)
            {
                AutoFormatExpression = PaymentLine."Currency Code";
                AutoFormatType = 1;
            }

            dataitem(InvoiceDetail; Integer)
            {
                DataItemTableView = sorting(Number);

                column(InvoiceNo; InvoiceNo) { }
                column(InvoiceDate; InvoiceDate) { }
                column(DocumentNo; DocumentNo) { }
                column(Description; Description) { }

                column(InvoiceAmount; InvoiceAmount)
                {
                    AutoFormatExpression = PaymentLine."Currency Code";
                    AutoFormatType = 1;
                }

                column(AmountPaid; AmountPaid)
                {
                    AutoFormatExpression = PaymentLine."Currency Code";
                    AutoFormatType = 1;
                }

                column(DiscountGiven; DiscountGiven)
                {
                    AutoFormatExpression = PaymentLine."Currency Code";
                    AutoFormatType = 1;
                }

                column(NetAmount; NetAmount)
                {
                    AutoFormatExpression = PaymentLine."Currency Code";
                    AutoFormatType = 1;
                }

                trigger OnPreDataItem()
                begin
                    BuildInvoiceDetails();

                    if DetailBuffer.IsEmpty() then
                        SetRange(Number, 1, 0)
                    else begin
                        SetRange(Number, 1, DetailBuffer.Count());
                        DetailBuffer.FindFirst();
                    end;
                end;

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then
                        if DetailBuffer.Next() = 0 then
                            CurrReport.Skip();
                    DetailBuffer.CalcFields(Amount);
                    DocumentNo := DetailBuffer."Document No.";
                    InvoiceNo := DetailBuffer."External Document No.";
                    InvoiceDate := DetailBuffer."Document Date";
                    Description := DetailBuffer.Description;

                    AmountPaid := Abs(DetailBuffer.Amount);

                    DiscountGiven := -DetailBuffer."Remaining Pmt. Disc. Possible";

                    if DetailBuffer."Accepted Payment Tolerance" <> 0 then
                        DiscountGiven := DiscountGiven -
                                         DetailBuffer."Accepted Payment Tolerance";

                    InvoiceAmount := AmountPaid + DiscountGiven;
                    NetAmount := AmountPaid - DiscountGiven;
                end;
            }

            trigger OnPreDataItem()
            begin
                if JournalTemplateName = '' then
                    Error(SelectBatchErr);

                if JournalBatchName = '' then
                    Error(SelectBatchErr);

                SetRange("Journal Template Name", JournalTemplateName);
                SetRange("Journal Batch Name", JournalBatchName);
                SetRange("Account Type", "Account Type"::Vendor);
                SetRange(
                    "Bank Payment Type",
                    "Bank Payment Type"::"Computer Check");
            end;

            trigger OnAfterGetRecord()
            begin
                Clear(Vendor);

                if PaymentLine.Amount = 0 then
                    CurrReport.Skip();

                if not Vendor.Get(PaymentLine."Account No.") then
                    CurrReport.Skip();
            end;
        }
    }

    rendering
    {
        layout(StubInformationLayout)
        {
            Type = RDLC;
            LayoutFile = './src/Reports/Layouts/PMISStubInformation.rdl';
            Caption = 'PMIS Stub Information';
        }
    }
    labels
    {
        VendorRefLblCaption = 'VENDOR REF.';
        VendorLblCaption = 'VENDOR';
        CheckNoLblCaption = 'CHECK NO.';
        CheckDateLblCaption = 'CHECK DATE';
        VoucherLblCaption = 'Document No.';
        InvoiceNoLblCaption = 'INVOICE NUMBER';
        InvoiceDateLblCaption = 'INV.DATE';
        ReferenceLblCaption = 'PO No.';
        InvoiceAmountLblCaption = 'INVOICE AMOUNT';
        AmountPaidLblCaption = 'AMOUNT PAID';
        DiscountTakenLblCaption = 'DISCOUNT TAKEN';
        NetAmountLblCaption = 'NET AMOUNT';
    }

    var
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
        DetailBuffer: Record "Vendor Ledger Entry" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";

        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];

        InvoiceNo: Code[35];
        InvoiceDate: Date;
        InvoiceAmount: Decimal;
        AmountPaid: Decimal;
        DiscountGiven: Decimal;
        NetAmount: Decimal;
        DocumentNo: Text;
        Description: Text;

        ReportTitleLbl: Label 'Multi Invoice Remittance';
        SelectBatchErr: Label
            'Select a Payment Journal batch before running this report.';
        NoApplicationsErr: Label
            'No applied vendor documents were found for payment document %1.';
        SettlementErr: Label
            'The payment-specific application calculation has not been implemented. Remittance output is stopped to prevent incorrect amounts.';

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
    end;

    procedure SetJournalBatch(
        NewJournalTemplateName: Code[10];
        NewJournalBatchName: Code[10])
    begin
        JournalTemplateName := NewJournalTemplateName;
        JournalBatchName := NewJournalBatchName;
    end;

    local procedure BuildInvoiceDetails()
    begin
        DetailBuffer.Reset();
        DetailBuffer.DeleteAll();

        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetAutoCalcFields(Amount);
        VendorLedgerEntry.SetRange(
            "Vendor No.", PaymentLine."Account No.");

        if PaymentLine."Applies-to Doc. No." <> '' then begin
            VendorLedgerEntry.SetRange(
                "Document Type", PaymentLine."Applies-to Doc. Type");
            VendorLedgerEntry.SetRange(
                "Document No.", PaymentLine."Applies-to Doc. No.");
        end else
            if PaymentLine."Applies-to ID" <> '' then
                VendorLedgerEntry.SetRange(
                    "Applies-to ID", PaymentLine."Applies-to ID")
            else
                exit;

        if VendorLedgerEntry.FindSet() then
            repeat
                DetailBuffer := VendorLedgerEntry;

                if not DetailBuffer.Insert() then;
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure CalculateSettlementAmounts()
    begin
        Clear(AmountPaid);
        Clear(DiscountGiven);
        Clear(NetAmount);


        // Implement using the vendor application calculation
        // from the installed standard Check (Stub/Check/Stub)
        // report 10411 and validate against actual PMIS checks.
        //
        // Do not substitute Remaining Amount or the entire
        // payment amount for document-level settlement amounts.

        //Error(SettlementErr);
    end;
}
