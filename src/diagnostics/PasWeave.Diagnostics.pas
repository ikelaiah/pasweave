unit PasWeave.Diagnostics;

{$mode objfpc}{$H+}

interface

type
  TDiagnosticSeverity = (dsWarning, dsError);

const
  DiagnosticCodeGeneric = 'PW000';

type
  TDiagnostic = class
  public
    Code: string;
    Severity: TDiagnosticSeverity;
    SourceFilename: string;
    SourceLine: Integer;
    SourceColumn: Integer;
    MessageText: string;
    Details: string;
    constructor Create(ASeverity: TDiagnosticSeverity;
      const ASourceFilename: string; ASourceLine, ASourceColumn: Integer;
      const AMessageText: string; const ADetails: string = '';
      const ACode: string = DiagnosticCodeGeneric);
  end;

function DiagnosticSeverityName(ASeverity: TDiagnosticSeverity): string;
function TryParseDiagnosticSeverity(const AValue: string;
  out ASeverity: TDiagnosticSeverity): Boolean;

implementation

uses
  SysUtils;

constructor TDiagnostic.Create(ASeverity: TDiagnosticSeverity;
  const ASourceFilename: string; ASourceLine, ASourceColumn: Integer;
  const AMessageText: string; const ADetails, ACode: string);
begin
  inherited Create;
  Code := ACode;
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

function TryParseDiagnosticSeverity(const AValue: string;
  out ASeverity: TDiagnosticSeverity): Boolean;
begin
  if SameText(AValue, 'warning') then
    ASeverity := dsWarning
  else if SameText(AValue, 'error') then
    ASeverity := dsError
  else
    Exit(False);
  Result := True;
end;

end.
