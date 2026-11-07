reportextension 50102 "PMIS Pick Instruction" extends "Pick Instruction"
{
    RDLCLayout = './src/ReportExtensions/Layouts/PickInstruction.rdl';
    dataset
    {
        add("Sales Header")
        {
            column(PMISSellToAddress1; SellToAddress[1]) { }
            column(PMISSellToAddress2; SellToAddress[2]) { }
            column(PMISSellToAddress3; SellToAddress[3]) { }
            column(PMISSellToAddress4; SellToAddress[4]) { }
            column(PMISSellToAddress5; SellToAddress[5]) { }
            column(PMISSellToAddress6; SellToAddress[6]) { }
            column(PMISSellToAddress7; SellToAddress[7]) { }
            column(PMISShipToAddress1; ShipToAddress[1]) { }
            column(PMISShipToAddress2; ShipToAddress[2]) { }
            column(PMISShipToAddress3; ShipToAddress[3]) { }
            column(PMISShipToAddress4; ShipToAddress[4]) { }
            column(PMISShipToAddress5; ShipToAddress[5]) { }
            column(PMISShipToAddress6; ShipToAddress[6]) { }
            column(PMISShipToAddress7; ShipToAddress[7]) { }

            column(PMISExternalDocumentNo; "External Document No.") { }
            column(PMISShipmentMethodCode; "Shipment Method Code") { }
            column(PMISPaymentTermsCode; "Payment Terms Code") { }
            column(PMISShpfyOrderNo; "Shpfy Order No.") { }
        }
        modify("Sales Header")
        {
            trigger OnAfterAfterGetRecord()

            begin
                FormatAddress.SalesHeaderShipTo(ShipToAddress, ShipToAddress, "Sales Header");
                FormatAddress.SalesHeaderSellTo(SellToAddress, "Sales Header");
            end;
        }
    }

    requestpage
    {
        trigger OnOpenPage()
        begin
            InitializeRequest(2);
        end;
    }
    labels
    {
        SoldToCaptionLbl = 'Sold To: ';
        ShipToCaptionLbl = 'Ship To: ';
        POCaptionLbl = 'P.O. #';
        ShipViaCaptionLbl = 'Ship Via: ';
        TermsCaptionLbl = 'Terms: ';
        ShopifyOrderNoCaptionLbl = 'Shopify Order No: ';
    }


    var
        FormatAddress: Codeunit "Format Address";
        ShipToAddress: array[8] of Text[100];
        SellToAddress: array[8] of Text[100];
}
