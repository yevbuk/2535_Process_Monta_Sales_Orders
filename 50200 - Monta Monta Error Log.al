table 50200 "Monta Error Log"
{
    DataClassification = CustomerContent;
    Caption = 'Monta Error Log';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; Description; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(3; UsedId; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'User Id';
        }
        field(4; "Run Date-Time"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Run Date-Time';
        }
        field(5; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Document No.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}