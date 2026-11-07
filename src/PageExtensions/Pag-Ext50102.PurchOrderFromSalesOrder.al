pageextension 50102 "Purch. Order From Sales Order" extends "Purch. Order From Sales Order"
{
    trigger OnOpenPage()
    begin
        UpdateRequisitionDescriptions();
    end;

    local procedure UpdateRequisitionDescriptions()
    var
        ReqLine: Record "Requisition Line";
        SalesLine: Record "Sales Line";
    begin
        ReqLine.Reset();
        ReqLine.SetRange("Demand Type", Database::"Sales Line");

        if ReqLine.FindSet(true) then
            repeat
                if SalesLine.Get(SalesLine."Document Type"::Order, ReqLine."Demand Order No.", ReqLine."Demand Line No.")
                then begin
                    if ReqLine.Description <> SalesLine.Description
                    then begin
                        ReqLine.Description := SalesLine.Description;
                        ReqLine.Modify(true);
                    end;
                end;
            until ReqLine.Next() = 0;
    end;
}
