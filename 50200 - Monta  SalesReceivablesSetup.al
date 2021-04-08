pageextension 50200 SalesReceivablesSetup extends "Sales & Receivables Setup"
{
    layout
    {
        addafter("Order Nos.")
        {
            field("Monta No. Series"; Rec."Monta No. Series")
            {
                ApplicationArea = All;
            }
        }
    }
}