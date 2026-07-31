unit CommentDialects;

{$mode objfpc}{$H+}

interface

/// Slash documentation.
procedure SlashOnly;

// Ordinary line comment, not PasWeave documentation.
procedure PlainSlashOnly;

{ Brace documentation. }
procedure BraceOnly;

(* Paren documentation. *)
procedure ParenOnly;

/// Mixed slash summary.
{
  Mixed brace detail.
  @param A Value from the caller.
}
(*
  Mixed paren detail.
  @returns The same value.
  @since 1.2
*)
function Mixed(const A: Integer): Integer;

{ This comment is separated from the declaration. }

procedure AfterBlankLine;

/// This slash comment is also separated.

procedure AfterSlashBlankLine;

{ Documentation attached to one declaration. }
procedure FirstAfterGroup;
procedure SecondAfterGroup;

{ This must not cross a brace compiler directive. }
{$IFDEF FPC}
procedure BraceDirectiveBarrier;
{$ENDIF}

(* This must not cross a paren compiler directive. *)
(*$IFDEF FPC*)
procedure ParenDirectiveBarrier;
(*$ENDIF*)

type
  { Types }
  TAfterSectionLabel = Integer;

  { procedure RemovedRoutine; }
  TAfterDisabledCode = Integer;

  TTrailingCommentFixture = record
    Previous: Integer; { This describes Previous, not Next. }
    Next: Integer;
  end;

  TVisibilityFixture = class
  private
    { Internal storage. }
    FSecret: Integer;
  public
    { Public accessor. }
    function Secret: Integer;
  end;

implementation

procedure SlashOnly;
begin
end;

procedure PlainSlashOnly;
begin
end;

procedure BraceOnly;
begin
end;

procedure ParenOnly;
begin
end;

function Mixed(const A: Integer): Integer;
begin
  Result := A;
end;

procedure AfterBlankLine;
begin
end;

procedure AfterSlashBlankLine;
begin
end;

procedure FirstAfterGroup;
begin
end;

procedure SecondAfterGroup;
begin
end;

procedure BraceDirectiveBarrier;
begin
end;

procedure ParenDirectiveBarrier;
begin
end;

function TVisibilityFixture.Secret: Integer;
begin
  Result := FSecret;
end;

end.
