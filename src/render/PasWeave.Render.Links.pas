unit PasWeave.Render.Links;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  PasWeave.Model;

function RenderMarkdownSeeLink(AProject: TDocProject; ACurrentUnit: TDocUnit;
  ADirective: TDocDirective): UTF8String;
function RenderHTMLSeeLink(AProject: TDocProject; ACurrentUnit: TDocUnit;
  ADirective: TDocDirective): UTF8String;

implementation

uses
  SysUtils, PasWeave.Render.Support;

function MarkdownCode(const AText: string): UTF8String;
begin
  Result := UTF8String('`' + StringReplace(AText, '`', '''',
    [rfReplaceAll]) + '`');
end;

function RenderMarkdownSeeLink(AProject: TDocProject; ACurrentUnit: TDocUnit;
  ADirective: TDocDirective): UTF8String;
var
  TargetSymbol: TDocSymbol;
  TargetUnit: TDocUnit;
  Target: string;
begin
  TargetSymbol := FindProjectSymbolByID(AProject, ADirective.TargetSymbolID,
    TargetUnit);
  if not Assigned(TargetSymbol) or not Assigned(TargetUnit) then
    Exit(MarkdownCode(ADirective.Subject));
  if TargetUnit = ACurrentUnit then
    Target := '#' + DocumentationSymbolAnchor(TargetSymbol)
  else
    Target := TargetUnit.Name + '.md#' + DocumentationSymbolAnchor(TargetSymbol);
  Result := '[' + MarkdownCode(ADirective.Subject) + '](' +
    UTF8String(Target) + ')';
end;

function RenderHTMLSeeLink(AProject: TDocProject; ACurrentUnit: TDocUnit;
  ADirective: TDocDirective): UTF8String;
var
  TargetSymbol: TDocSymbol;
  TargetUnit: TDocUnit;
  Target: string;
begin
  TargetSymbol := FindProjectSymbolByID(AProject, ADirective.TargetSymbolID,
    TargetUnit);
  if not Assigned(TargetSymbol) or not Assigned(TargetUnit) then
    Exit('<code>' + EscapeHTML(ADirective.Subject) + '</code>');
  if TargetUnit = ACurrentUnit then
    Target := '#' + DocumentationSymbolAnchor(TargetSymbol)
  else
    Target := TargetUnit.Name + '.html#' + DocumentationSymbolAnchor(TargetSymbol);
  Result := '<a href="' + EscapeHTML(Target) + '"><code>' +
    EscapeHTML(ADirective.Subject) + '</code></a>';
end;

end.
