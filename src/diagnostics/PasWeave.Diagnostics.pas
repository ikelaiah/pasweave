unit PasWeave.Diagnostics;

{$mode objfpc}{$H+}

interface

type
  TDiagnosticSeverity = (dsWarning, dsError);

  TDiagnostic = class
  public
    Severity: TDiagnosticSeverity;
    SourceFilename: string;
    SourceLine: Integer;
    SourceColumn: Integer;
    MessageText: string;
    Details: string;
    constructor Create(ASeverity: TDiagnosticSeverity;
      const ASourceFilename: string; ASourceLine, ASourceColumn: Integer;
      const AMessageText: string; const ADetails: string = '');
  end;

function DiagnosticSeverityName(ASeverity: TDiagnosticSeverity): string;

implementation

constructor TDiagnostic.Create(ASeverity: TDiagnosticSeverity;
  const ASourceFilename: string; ASourceLine, ASourceColumn: Integer;
  const AMessageText: string; const ADetails: string);
begin
  inherited Create;
  Severity := ASeverity;
  SourceFilename := ASourceFilename;
  SourceLine := ASourceLine;
  SourceColumn := ASourceColumn;
  MessageText := AMessageText;
  Details := ADetails;
end;

function DiagnosticSeverityName(ASeverity: TDiagnosticSeverity): string;
begin
  case ASeverity of
    dsWarning: Result := 'warning';
    dsError: Result := 'error';
  end;
end;

end.
