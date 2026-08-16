unit PasWeave.Hashing;

{$mode objfpc}{$H+}

interface

uses
  Classes;

type
  TSHA256Digest = array[0..31] of Byte;

  TSHA256State = record
    State: array[0..7] of Cardinal;
    Buffer: array[0..63] of Byte;
    BufferLength: Integer;
    TotalBytes: QWord;
  end;

procedure SHA256Init(out AState: TSHA256State);
procedure SHA256Update(var AState: TSHA256State; const AData; ALength: Integer);
procedure SHA256Final(var AState: TSHA256State; out ADigest: TSHA256Digest);

function SHA256Hex(const AData; ALength: Integer): string;
function SHA256HexString(const AText: string): string;
function SHA256HexStream(AStream: TStream): string;
function SHA256HexFile(const AFilename: string): string;
function DigestHex(const ADigest: TSHA256Digest): string;

implementation

uses
  SysUtils;

const
  SHA256K: array[0..63] of Cardinal = (
    $428a2f98, $71374491, $b5c0fbcf, $e9b5dba5, $3956c25b, $59f111f1,
    $923f82a4, $ab1c5ed5, $d807aa98, $12835b01, $243185be, $550c7dc3,
    $72be5d74, $80deb1fe, $9bdc06a7, $c19bf174, $e49b69c1, $efbe4786,
    $0fc19dc6, $240ca1cc, $2de92c6f, $4a7484aa, $5cb0a9dc, $76f988da,
    $983e5152, $a831c66d, $b00327c8, $bf597fc7, $c6e00bf3, $d5a79147,
    $06ca6351, $14292967, $27b70a85, $2e1b2138, $4d2c6dfc, $53380d13,
    $650a7354, $766a0abb, $81c2c92e, $92722c85, $a2bfe8a1, $a81a664b,
    $c24b8b70, $c76c51a3, $d192e819, $d6990624, $f40e3585, $106aa070,
    $19a4c116, $1e376c08, $2748774c, $34b0bcb5, $391c0cb3, $4ed8aa4a,
    $5b9cca4f, $682e6ff3, $748f82ee, $78a5636f, $84c87814, $8cc70208,
    $90befffa, $a4506ceb, $bef9a3f7, $c67178f2
  );

function RotateRight(const AValue: Cardinal; const AShift: Cardinal): Cardinal;
begin
  Result := (AValue shr AShift) or (AValue shl (32 - AShift));
end;

procedure SHA256Init(out AState: TSHA256State);
begin
  AState.State[0] := $6a09e667;
  AState.State[1] := $bb67ae85;
  AState.State[2] := $3c6ef372;
  AState.State[3] := $a54ff53a;
  AState.State[4] := $510e527f;
  AState.State[5] := $9b05688c;
  AState.State[6] := $1f83d9ab;
  AState.State[7] := $5be0cd19;
  AState.BufferLength := 0;
  AState.TotalBytes := 0;
end;

procedure SHA256Compress(var AState: TSHA256State;
  const ABlock: array of Byte);
var
  W: array[0..63] of Cardinal;
  A, B, C, D, E, F, G, H: Cardinal;
  T1, T2: Cardinal;
  I: Integer;
begin
  for I := 0 to 15 do
    W[I] := (Cardinal(ABlock[I * 4]) shl 24) or
      (Cardinal(ABlock[I * 4 + 1]) shl 16) or
      (Cardinal(ABlock[I * 4 + 2]) shl 8) or
      Cardinal(ABlock[I * 4 + 3]);
  for I := 16 to 63 do
    W[I] := (RotateRight(W[I - 15], 7) xor RotateRight(W[I - 15], 18) xor
      (W[I - 15] shr 3)) + W[I - 7] +
      (RotateRight(W[I - 2], 17) xor RotateRight(W[I - 2], 19) xor
      (W[I - 2] shr 10)) + W[I - 16];

  A := AState.State[0];
  B := AState.State[1];
  C := AState.State[2];
  D := AState.State[3];
  E := AState.State[4];
  F := AState.State[5];
  G := AState.State[6];
  H := AState.State[7];

  for I := 0 to 63 do
  begin
    T1 := H + (RotateRight(E, 6) xor RotateRight(E, 11) xor
      RotateRight(E, 25)) + ((E and F) xor (not E and G)) + SHA256K[I] +
      W[I];
    T2 := (RotateRight(A, 2) xor RotateRight(A, 13) xor RotateRight(A, 22)) +
      ((A and B) xor (A and C) xor (B and C));
    H := G;
    G := F;
    F := E;
    E := D + T1;
    D := C;
    C := B;
    B := A;
    A := T1 + T2;
  end;

  AState.State[0] := AState.State[0] + A;
  AState.State[1] := AState.State[1] + B;
  AState.State[2] := AState.State[2] + C;
  AState.State[3] := AState.State[3] + D;
  AState.State[4] := AState.State[4] + E;
  AState.State[5] := AState.State[5] + F;
  AState.State[6] := AState.State[6] + G;
  AState.State[7] := AState.State[7] + H;
end;

procedure SHA256Update(var AState: TSHA256State; const AData; ALength: Integer);
var
  P: PByte;
begin
  P := @AData;
  AState.TotalBytes := AState.TotalBytes + QWord(ALength);
  while ALength > 0 do
  begin
    AState.Buffer[AState.BufferLength] := P^;
    Inc(P);
    Dec(ALength);
    Inc(AState.BufferLength);
    if AState.BufferLength = 64 then
    begin
      SHA256Compress(AState, AState.Buffer);
      AState.BufferLength := 0;
    end;
  end;
end;

procedure SHA256Final(var AState: TSHA256State; out ADigest: TSHA256Digest);
var
  BitLength: QWord;
  I: Integer;
begin
  BitLength := AState.TotalBytes * 8;

  AState.Buffer[AState.BufferLength] := $80;
  Inc(AState.BufferLength);

  if AState.BufferLength > 56 then
  begin
    while AState.BufferLength < 64 do
    begin
      AState.Buffer[AState.BufferLength] := 0;
      Inc(AState.BufferLength);
    end;
    SHA256Compress(AState, AState.Buffer);
    AState.BufferLength := 0;
  end;

  while AState.BufferLength < 56 do
  begin
    AState.Buffer[AState.BufferLength] := 0;
    Inc(AState.BufferLength);
  end;
  for I := 0 to 7 do
    AState.Buffer[56 + I] := Byte(BitLength shr (56 - I * 8));
  AState.BufferLength := 64;
  SHA256Compress(AState, AState.Buffer);
  AState.BufferLength := 0;

  for I := 0 to 7 do
  begin
    ADigest[I * 4] := Byte(AState.State[I] shr 24);
    ADigest[I * 4 + 1] := Byte(AState.State[I] shr 16);
    ADigest[I * 4 + 2] := Byte(AState.State[I] shr 8);
    ADigest[I * 4 + 3] := Byte(AState.State[I]);
  end;
end;

function DigestHex(const ADigest: TSHA256Digest): string;
const
  HexDigits: array[0..15] of Char = '0123456789abcdef';
var
  I: Integer;
  B: Byte;
begin
  Result := '';
  for I := 0 to 31 do
  begin
    B := ADigest[I];
    Result := Result + HexDigits[B shr 4] + HexDigits[B and $0F];
  end;
end;

function SHA256Hex(const AData; ALength: Integer): string;
var
  State: TSHA256State;
  Digest: TSHA256Digest;
begin
  SHA256Init(State);
  if ALength > 0 then
    SHA256Update(State, AData, ALength);
  SHA256Final(State, Digest);
  Result := DigestHex(Digest);
end;

function SHA256HexString(const AText: string): string;
begin
  if Length(AText) = 0 then
    Result := SHA256Hex(AText, 0)
  else
    Result := SHA256Hex(AText[1], Length(AText));
end;

function SHA256HexStream(AStream: TStream): string;
var
  State: TSHA256State;
  Digest: TSHA256Digest;
  Buffer: array[0..65535] of Byte;
  ReadCount: Integer;
begin
  SHA256Init(State);
  repeat
    ReadCount := AStream.Read(Buffer, SizeOf(Buffer));
    if ReadCount > 0 then
      SHA256Update(State, Buffer[0], ReadCount);
  until ReadCount <= 0;
  SHA256Final(State, Digest);
  Result := DigestHex(Digest);
end;

function SHA256HexFile(const AFilename: string): string;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    Result := SHA256HexStream(Stream);
  finally
    Stream.Free;
  end;
end;

end.
