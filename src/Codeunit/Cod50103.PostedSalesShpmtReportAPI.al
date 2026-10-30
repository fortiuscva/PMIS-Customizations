codeunit 50103 "Posted Sales Shpmt. Report API"
{
    [ServiceEnabled]
    procedure GetPSSPDF(orderNo: Code[20]): Text
    var
        SalesShpmntHeader: Record "Sales Shipment Header";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStr: OutStream;
        InStr: InStream;
        RecRef: RecordRef;
    begin
        SalesShpmntHeader.SetRange("Order No.", orderNo);

        if not SalesShpmntHeader.FindFirst() then
            exit;
        TempBlob.CreateOutStream(OutStr);

        RecRef.GetTable(SalesShpmntHeader);

        Report.SaveAs(Report::"Sales Shipment NA", '', ReportFormat::Pdf, OutStr, RecRef);

        TempBlob.CreateInStream(InStr);

        exit(Base64Convert.ToBase64(InStr));
    end;
}
