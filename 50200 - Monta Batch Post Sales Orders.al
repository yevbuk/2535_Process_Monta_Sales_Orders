report 50200 "Monta Batch Post Sales Orders"
{
    Caption = 'Monta Batch Post Sales Orders';
    ProcessingOnly = true;
    ApplicationArea = All;
    UsageCategory = Lists;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Order));
            RequestFilterFields = "No.", Status;
            RequestFilterHeading = 'Sales Order';

            trigger OnPreDataItem()
            var
                SalesReceivablesSetup: Record "Sales & Receivables Setup";
            begin
                SalesReceivablesSetup.Get();
                SalesReceivablesSetup.TestField("Monta No. Series");

                "Sales Header".SetRange("No. Series", SalesReceivablesSetup."Monta No. Series");

                CounterTotal := "Sales Header".Count();

                if GuiAllowed then
                    Window.OPEN(Text001);
            end;

            trigger OnAfterGetRecord()
            begin
                if ItemChargeExists("Sales Header"."No.") then begin
                    AssignSalesDocumentItemCharges("Sales Header");
                    Commit();
                end;

                Counter := Counter + 1;

                if GuiAllowed then begin
                    Window.Update(1, "No.");
                    Window.Update(2, Round(Counter / CounterTotal * 10000, 1));
                end;

                "Sales Header".Invoice := true;
                "Sales Header".Ship := true;

                Clear(SalesPost);

                DocumentNo := "Sales Header"."No.";

                if SalesPost.Run("Sales Header") then begin
                    CounterOK := CounterOK + 1;
                    UpdateErrorLog(DocumentNo);
                end else
                    InsertErrorLog(DocumentNo);
            end;

            trigger OnPostDataItem()
            begin
                if GuiAllowed then begin
                    Window.Close();
                    Message(Text002, CounterOK, CounterTotal);
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Ship; ShipReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ship';
                        ToolTip = 'Specifies whether the orders will be shipped when posted. If you place a check in the box, it will apply to all the orders that are posted.';
                    }
                    field(Invoice; InvReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Invoice';
                        ToolTip = 'Specifies whether the orders will be invoiced when posted. If you place a check in the box, it will apply to all the orders that are posted.';
                    }
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that the program will use as the document and/or posting date when you post if you place a checkmark in one or both of the following boxes.';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if the new posting date will be applied.';

                        trigger OnValidate()
                        begin
                            if ReplacePostingDate then
                                Message(Text003);
                        end;
                    }
                    field(ReplaceDocumentDate; ReplaceDocumentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if you want to replace the sales orders'' document date with the date in the Posting Date field.';
                    }
                    field(CalcInvDisc; CalcInvDisc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the orders before posting.';

                        trigger OnValidate()
                        var
                            SalesReceivablesSetup: Record "Sales & Receivables Setup";
                        begin
                            SalesReceivablesSetup.Get();
                            SalesReceivablesSetup.TestField("Calc. Inv. Discount", false);
                        end;
                    }
                    field(PrintDoc; PrintDoc)
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = PrintDocVisible;
                        Caption = 'Print';
                        ToolTip = 'Specifies if you want to print the order after posting. In the Report Output Type field on the Sales & Receivables page, you define if the report will be printed or output as a PDF.';

                        trigger OnValidate()
                        var
                            SalesReceivablesSetup: Record "Sales & Receivables Setup";
                        begin
                            if PrintDoc then begin
                                SalesReceivablesSetup.Get();
                                if SalesReceivablesSetup."Post with Job Queue" then
                                    SalesReceivablesSetup.TestField("Post & Print with Job Queue");
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            SalesReceivablesSetup: Record "Sales & Receivables Setup";
        begin
            SalesReceivablesSetup.Get();
            CalcInvDisc := SalesReceivablesSetup."Calc. Inv. Discount";
            ReplacePostingDate := false;
            ReplaceDocumentDate := false;
            PrintDoc := false;
            PrintDocVisible := SalesReceivablesSetup."Post & Print with Job Queue";
        end;
    }

    labels
    {
    }

    local procedure ItemChargeExists(DocNo: Code[20]): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        exit(not SalesLine.IsEmpty());
    end;

    local procedure AssignSalesDocumentItemCharges(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        if SalesLine.FindSet() then
            repeat
                AssignSalesLineItemCharges(SalesLine);
            until SalesLine.Next() = 0;
    end;

    local procedure AssignSalesLineItemCharges(SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        AssignItemChargeSales: Codeunit "Item Charge Assgnt. (Sales)";
        ItemChargeAssgntLineAmt: Decimal;
    begin
        SalesLine.TestField("No.");
        SalesLine.TestField(Quantity);
        SalesLine.TestField(Type, SalesLine.Type::"Charge (Item)");

        SalesHeader.get(SalesLine."Document Type", SalesLine."Document No.");
        Currency.Initialize(SalesHeader."Currency Code");
        if (SalesLine."Inv. Discount Amount" = 0) and (SalesLine."Line Discount Amount" = 0) and
           (not SalesHeader."Prices Including VAT")
        then
            ItemChargeAssgntLineAmt := SalesLine."Line Amount"
        else
            if SalesHeader."Prices Including VAT" then
                ItemChargeAssgntLineAmt :=
                  Round(SalesLine.CalcLineAmount() / (1 + SalesLine."VAT %" / 100), Currency."Amount Rounding Precision")
            else
                ItemChargeAssgntLineAmt := SalesLine.CalcLineAmount();

        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetRange("Document Type", SalesLine."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", SalesLine."Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", SalesLine."Line No.");
        ItemChargeAssgntSales.SetRange("Item Charge No.", SalesLine."No.");
        if not ItemChargeAssgntSales.FindLast() then begin
            ItemChargeAssgntSales."Document Type" := SalesLine."Document Type";
            ItemChargeAssgntSales."Document No." := SalesLine."Document No.";
            ItemChargeAssgntSales."Document Line No." := SalesLine."Line No.";
            ItemChargeAssgntSales."Item Charge No." := SalesLine."No.";
            ItemChargeAssgntSales."Unit Cost" :=
              Round(ItemChargeAssgntLineAmt / SalesLine.Quantity, Currency."Unit-Amount Rounding Precision");
        end;

        ItemChargeAssgntLineAmt :=
           Round(ItemChargeAssgntLineAmt * (SalesLine."Qty. to Invoice" / SalesLine.Quantity), Currency."Amount Rounding Precision");

        if SalesLine.IsCreditDocType() then
            AssignItemChargeSales.CreateDocChargeAssgn(ItemChargeAssgntSales, SalesLine."Return Receipt No.")
        else
            AssignItemChargeSales.CreateDocChargeAssgn(ItemChargeAssgntSales, SalesLine."Shipment No.");
        Clear(AssignItemChargeSales);
        Commit();

        SalesLine.CalcFields("Qty. to Assign", "Qty. Assigned");
        AssignItemChargeSales.AssignItemCharges(SalesLine, SalesLine."Qty. to Invoice" + SalesLine."Quantity Invoiced" - SalesLine."Qty. Assigned", ItemChargeAssgntLineAmt, AssignItemChargeSales.AssignEquallyMenuText());
    end;


    local procedure InsertErrorLog(DocNo: Code[20])
    var
        MontaErrorLog: Record "Monta Error Log";
    begin
        MontaErrorLog.SetRange("Document No.", DocNo);
        if MontaErrorLog.FindFirst() then begin
            MontaErrorLog.Description := CopyStr(GetLastErrorText(), 1, MaxStrLen(MontaErrorLog.Description));
            MontaErrorLog.Modify();
            Commit();
        end else begin
            MontaErrorLog.Init();
            MontaErrorLog."Document No." := DocNo;
            MontaErrorLog.UsedId := UserId;
            MontaErrorLog."Run Date-Time" := CurrentDateTime();
            MontaErrorLog.Description := CopyStr(GetLastErrorText(), 1, MaxStrLen(MontaErrorLog.Description));
            MontaErrorLog.Insert();
            Commit();
        end;
    end;

    local procedure UpdateErrorLog(DocNo: Code[20])
    var
        MontaErrorLog: Record "Monta Error Log";
    begin
        MontaErrorLog.SetRange("Document No.", DocNo);
        if MontaErrorLog.FindFirst() then
            MontaErrorLog.Delete();
    end;



    var

        Text001: Label 'Posting orders  #1########## @2@@@@@@@@@@@@@';
        Text002: Label '%1 orders out of a total of %2 have now been posted.';
        Text003: Label 'The exchange rate associated with the new posting date on the sales header will not apply to the sales lines.';
        ShipReq: Boolean;
        InvReq: Boolean;
        PostingDateReq: Date;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        CalcInvDisc: Boolean;
        PrintDoc: Boolean;
        [InDataSet]
        PrintDocVisible: Boolean;

        Counter: Integer;
        CounterOK: Integer;
        CounterTotal: Integer;
        Window: Dialog;

        SalesPost: Codeunit "Sales-Post";
        DocumentNo: Code[20];

    procedure InitializeRequest(ShipParam: Boolean; InvoiceParam: Boolean; PostingDateParam: Date; ReplacePostingDateParam: Boolean; ReplaceDocumentDateParam: Boolean; CalcInvDiscParam: Boolean)
    begin
        ShipReq := ShipParam;
        InvReq := InvoiceParam;
        PostingDateReq := PostingDateParam;
        ReplacePostingDate := ReplacePostingDateParam;
        ReplaceDocumentDate := ReplaceDocumentDateParam;
        CalcInvDisc := CalcInvDiscParam;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesBatchPostMgt(var SalesHeader: Record "Sales Header"; var ShipReq: Boolean; var InvReq: Boolean)
    begin
    end;
}