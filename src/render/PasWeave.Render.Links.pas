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
function RenderMarkdownSymbolLink(AProject: TDocProject;
  ACurrentUnit: TDocUnit; const ATargetSymbolID,
  ADisplayName: string): UTF8String;
function RenderHTMLSymbolLink(AProject: TDocProject;
  ACurrentUnit: TDocUnit; const ATargetSymbolID,
  ADisplayName: string): UTF8String;

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
begin
  Result := RenderMarkdownSymbolLink(AProject, ACurrentUnit,
    ADirective.TargetSymbolID, ADirective.Subject);
end;

function RenderMarkdownSymbolLink(AProject: TDocProject;
  ACurrentUnit: TDocUnit; const ATargetSymbolID,
  ADisplayName: string): UTF8String;
var
  TargetSymbol: TDocSymbol;
  TargetUnit: TDocUnit;
  Target: string;
begin
  TargetSymbol := FindProjectSymbolByID(AProject, ATargetSymbolID, TargetUnit);
  if not Assigned(TargetSymbol) or not Assigned(TargetUnit) then
    Exit(MarkdownCode(ADisplayName));
  if TargetUnit = ACurrentUnit then
    Target := '#' + DocumentationSymbolAnchor(TargetSymbol)
  else
    Target := TargetUnit.Name + '.md#' + DocumentationSymbolAnchor(TargetSymbol);
  Result := '[' + MarkdownCode(ADisplayName) + '](' +
    UTF8String(Target) + ')';
end;

function RenderHTMLSeeLink(AProject: TDocProject; ACurrentUnit: TDocUnit;
  ADirective: TDocDirective): UTF8String;
begin
  Result := RenderHTMLSymbolLink(AProject, ACurrentUnit,
    ADirective.TargetSymbolID, ADirective.Subject);
end;

function RenderHTMLSymbolLink(AProject: TDocProject;
  ACurrentUnit: TDocUnit; const ATargetSymbolID,
  ADisplayName: string): UTF8String;
var
  TargetSymbol: TDocSymbol;
  TargetUnit: TDocUnit;
  Target: string;
begin
  TargetSymbol := FindProjectSymbolByID(AProject, ATargetSymbolID, TargetUnit);
  if not Assigned(TargetSymbol) or not Assigned(TargetUnit) then
    Exit('<code>' + EscapeHTML(ADisplayName) + '</code>');
  if TargetUnit = ACurrentUnit then
    Target := '#' + DocumentationSymbolAnchor(TargetSymbol)
  else
    Target := TargetUnit.Name + '.html#' + DocumentationSymbolAnchor(TargetSymbol);
  Result := '<a href="' + EscapeHTML(Target) + '"><code>' +
    EscapeHTML(ADisplayName) + '</code></a>';
end;

end.
