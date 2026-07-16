codeunit 50102 "PMIS Report API"
{
    [ServiceEnabled]
    procedure GetPSIPDF(documentNo: Code[20]): Text
    var
        SalesInvHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStr: OutStream;
        InStr: InStream;
        RecRef: RecordRef;
    begin
        SalesInvHeader.SetRange("No.", documentNo);

        if not SalesInvHeader.FindFirst() then
            exit;
        TempBlob.CreateOutStream(OutStr);

        RecRef.GetTable(SalesInvHeader);

        Report.SaveAs(Report::"Standard Sales - Invoice", '', ReportFormat::Pdf, OutStr, RecRef);

        TempBlob.CreateInStream(InStr);

        exit(Base64Convert.ToBase64(InStr));
    end;

    [ServiceEnabled]
    procedure GetCustomerStatementPDF(customerNo: Code[20];
            fromDate: Date;
            toDate: Date): Text
    Var
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStr: OutStream;
        InStr: InStream;
        RecRef: RecordRef;
        StandardStatement: Report "Standard Statement";
        Parameters: Text;
        RequestXml: Text;
    begin
        Customer.Reset();
        Customer.SetRange("No.", customerNo);

        if not Customer.FindFirst() then
            exit;

        Parameters :=
    '<?xml version="1.0" standalone="yes"?>' +
    '<ReportParameters name="Standard Statement">' +
        '<Options>' +
            '<Field name="StartDate">' + Format(fromDate, 0, 9) + '</Field>' +
            '<Field name="EndDate">' + format(toDate, 0, 9) + '</Field>' +
            '<Field name="StatementStyle">0</Field>' +
            '<Field name="PrintEntriesDue">false</Field>' +
            '<Field name="PrintAllHavingEntry">false</Field>' +
            '<Field name="PrintAllHavingBal">true</Field>' +
            '<Field name="PrintReversedEntries">false</Field>' +
            '<Field name="PrintUnappliedEntries">false</Field>' +
            '<Field name="IncludeAgingBand">false</Field>' +
            '<Field name="PeriodLength">1M+CM</Field>' +
            '<Field name="DateChoice">0</Field>' +
            '<Field name="LogInteraction">true</Field>' +
            '<Field name="SupportedOutputMethod">0</Field>' +
            '<Field name="ChosenOutputMethod">0</Field>' +
            '<Field name="PrintIfEmailIsMissing">false</Field>' +
        '</Options>' +
    '</ReportParameters>';


        TempBlob.CreateOutStream(OutStr);

        RecRef.GetTable(Customer);

        Report.SaveAs(Report::"Standard Statement", Parameters, ReportFormat::Pdf, OutStr, RecRef);
        TempBlob.CreateInStream(InStr);

        exit(Base64Convert.ToBase64(InStr));
    end;
}
