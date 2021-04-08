page 50200 "Monta Error Logs"
{
    Caption = 'Monta Error Logs';
    ApplicationArea = All;
    UsageCategory = Lists;
    PageType = List;
    SourceTable = "Monta Error Log";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(UsedId; Rec.UsedId)
                {
                    ApplicationArea = All;
                }
                field("Run Date-Time"; Rec."Run Date-Time")
                {
                    ApplicationArea = All;
                }
            }
        }

    }
}