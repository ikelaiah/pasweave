/// End-to-end checks for the `pasweave` command-line contract.
///
/// The suite starts the compiled CLI, so it verifies option parsing, exit
/// codes, incremental messaging, and diagnostics exactly as a user sees them.
/// Set `PASWEAVE_BIN` to test another executable; the default is
/// `build/bin/pasweave` (`.exe` on Windows) relative to the repository root.
program test_cli;

{$mode objfpc}{$H+}{$J+}

uses
  Classes, SysUtils, Pipes, Process, PasWeave.TestSupport, PasWeave.Version;

const
  BasicOutputDirectory = 'build/cli-test/basic';
  CoverageOutputDirectory = 'build/cli-test/coverage';
  PartialOutputDirectory = 'build/cli-test/partial';
  SourceLinkOutputDirectory = 'build/cli-test/source-link';
  SimpleFixture = 'tests/fixtures/SimpleUnit.pas';
  PartialFixture = 'tests/fixtures/partial';

type
  TTestCase = procedure;

var
  Failures: Integer;

function BinaryPath: string;
begin
  Result := GetEnvironmentVariable('PASWEAVE_BIN');
  if Result = '' then
  begin
    Result := 'build/bin/pasweave';
    {$IFDEF MSWINDOWS}
    Result := Result + '.exe';
    {$ENDIF}
  end;
end;

function StreamText(AStream: TMemoryStream): string;
begin
  AStream.Position := 0;
  SetLength(Result, AStream.Size);
  if AStream.Size > 0 then
    AStream.ReadBuffer(Result[1], AStream.Size);
end;

// Reads whatever is buffered so a full pipe can never deadlock the child.
procedure DrainPipe(AStream: TInputPipeStream; ATarget: TMemoryStream);
var
  Available: LongInt;
  ReadCount: LongInt;
  Buffer: array[0..4095] of Byte;
begin
  Available := AStream.NumBytesAvailable;
  while Available > 0 do
  begin
    if Available > SizeOf(Buffer) then
      ReadCount := AStream.Read(Buffer, SizeOf(Buffer))
    else
      ReadCount := AStream.Read(Buffer, Available);
    if ReadCount <= 0 then
      Exit;
    ATarget.WriteBuffer(Buffer, ReadCount);
    Dec(Available, ReadCount);
  end;
end;

function RunCli(const AArguments: array of string;
  out AStdOut, AStdErr: string): Integer;
var
  Process: TProcess;
  OutStream: TMemoryStream;
  ErrStream: TMemoryStream;
  I: Integer;
begin
  AStdOut := '';
  AStdErr := '';
  Process := TProcess.Create(nil);
  OutStream := TMemoryStream.Create;
  ErrStream := TMemoryStream.Create;
  try
    Process.Executable := BinaryPath;
    for I := Low(AArguments) to High(AArguments) do
      Process.Parameters.Add(AArguments[I]);
    Process.Options := [poUsePipes, poNoConsole];
    Process.Execute;
    while Process.Running do
    begin
      DrainPipe(Process.Output, OutStream);
      DrainPipe(Process.Stderr, ErrStream);
      Sleep(10);
    end;
    DrainPipe(Process.Output, OutStream);
    DrainPipe(Process.Stderr, ErrStream);
    Process.WaitOnExit;
    { ExitCode applies the platform wait-status decoding (wexitstatus on
      Unix); ExitStatus would return the raw wait status there. }
    Result := Process.ExitCode;
    AStdOut := StreamText(OutStream);
    AStdErr := StreamText(ErrStream);
  finally
    ErrStream.Free;
    OutStream.Free;
    Process.Free;
  end;
end;

procedure Expect(const ADescription: string; ACondition: Boolean);
begin
  Check(ACondition, ADescription);
end;

procedure RunCase(const AName: string; ACase: TTestCase);
begin
  try
    BeginTest(AName);
    ACase;
  except
    on E: Exception do
    begin
      WriteLn(StdErr, 'FAIL: ', E.Message);
      Inc(Failures);
    end;
  end;
end;

procedure CheckVersionAndUsage;
var
  StdOut: string;
  StdErr: string;
  ExitCode: Integer;
begin
  ExitCode := RunCli(['--version'], StdOut, StdErr);
  Expect('--version should exit 0', ExitCode = 0);
  Expect('--version should print the version', Pos(PasWeaveVersion, StdOut) > 0);

  ExitCode := RunCli(['--help'], StdOut, StdErr);
  Expect('--help should exit 0', ExitCode = 0);
  Expect('--help should document the build command',
    Pos('pasweave build', StdOut) > 0);

  ExitCode := RunCli([], StdOut, StdErr);
  Expect('no arguments should print usage and exit 0', ExitCode = 0);
  Expect('no arguments should print usage', Pos('pasweave build', StdOut) > 0);
end;

procedure CheckUsageErrors;
var
  Actual: Integer;
  StdErr: string;
  StdOut: string;

  procedure ExpectUsageError(const ADescription: string;
    const AArguments: array of string; const AExpectedMessage: string);
  begin
    Actual := RunCli(AArguments, StdOut, StdErr);
    Expect(ADescription + ' should exit 2', Actual = 2);
    Expect(ADescription + ' should explain the problem',
      Pos(AExpectedMessage, StdErr) > 0);
  end;

begin
  ExpectUsageError('an unknown command', ['not-a-command'], 'unknown command');
  ExpectUsageError('an unknown option',
    ['build', SimpleFixture, '--bogus'], 'unknown option');
  ExpectUsageError('a missing option value',
    ['build', SimpleFixture, '--output'], 'missing value for');
  ExpectUsageError('a missing source path', ['build'],
    'missing unit or source directory');
  ExpectUsageError('a missing source file',
    ['build', 'tests/fixtures/does-not-exist.pas'], 'does not exist');
  ExpectUsageError('an invalid comment style',
    ['build', SimpleFixture, '--doc-comments=bogus'],
    'invalid documentation comment styles');
  ExpectUsageError('an invalid project mark',
    ['build', SimpleFixture, '--project-mark=TOOLONG'],
    'must be 1 to 4 alphanumeric characters');
  ExpectUsageError('an invalid coverage threshold',
    ['build', SimpleFixture, '--min-documentation-coverage=101'],
    'must be an integer from 0 to 100');
  ExpectUsageError('a partial source-link configuration',
    ['build', SimpleFixture,
     '--repository-url=https://github.com/example/repo'],
    'source-link');
end;

procedure CheckBuildAndIncremental;
var
  StdOut: string;
  StdErr: string;
  ExitCode: Integer;
begin
  DeleteTree('build/cli-test');

  ExitCode := RunCli(['build', SimpleFixture,
    '--output=' + BasicOutputDirectory], StdOut, StdErr);
  Expect('a fixture build should exit 0', ExitCode = 0);
  Expect('a fixture build should write the project index',
    FileExists(BasicOutputDirectory + '/html/index.html'));
  Expect('a fixture build should write the symbol index',
    FileExists(BasicOutputDirectory + '/html/symbols.html'));
  Expect('a fixture build should write the manifest',
    FileExists(BasicOutputDirectory + '/manifest.json'));

  ExitCode := RunCli(['build', SimpleFixture,
    '--output', BasicOutputDirectory], StdOut, StdErr);
  Expect('an unchanged rebuild should exit 0', ExitCode = 0);
  Expect('an unchanged rebuild should report up-to-date',
    Pos('[up-to-date]', StdOut) > 0);

  ExitCode := RunCli(['build', SimpleFixture, '--output', BasicOutputDirectory,
    '--clean'], StdOut, StdErr);
  Expect('--clean should exit 0', ExitCode = 0);
  Expect('--clean should force a full rebuild', Pos('[up-to-date]', StdOut) = 0);

  WriteTextFile(BasicOutputDirectory + '/manifest.json', 'not valid json {');
  ExitCode := RunCli(['build', SimpleFixture,
    '--output', BasicOutputDirectory], StdOut, StdErr);
  Expect('a corrupted manifest should rebuild instead of failing',
    ExitCode = 0);
  Expect('a corrupted manifest should warn',
    Pos('manifest.json is unreadable or invalid', StdErr) > 0);
end;

procedure CheckFailurePolicies;
var
  StdOut: string;
  StdErr: string;
  ExitCode: Integer;
begin
  ExitCode := RunCli(['build', SimpleFixture, '--output',
    CoverageOutputDirectory, '--min-documentation-coverage=100'],
    StdOut, StdErr);
  Expect('a coverage miss should fail by default (PW411 is an error)',
    ExitCode = 1);
  Expect('a coverage miss should emit PW411', Pos('PW411', StdOut) > 0);

  ExitCode := RunCli(['build', SimpleFixture, '--output',
    CoverageOutputDirectory, '--min-documentation-coverage=0'],
    StdOut, StdErr);
  Expect('meeting the coverage minimum should exit 0', ExitCode = 0);

  ExitCode := RunCli(['build', PartialFixture, '--output',
    PartialOutputDirectory], StdOut, StdErr);
  Expect('a parse error should fail the build', ExitCode = 1);
  Expect('a parse error should be reported',
    Pos('[error ', StdOut) > 0);
end;

procedure CheckSourceLinkValidation;
var
  StdOut: string;
  StdErr: string;
  ExitCode: Integer;
begin
  ExitCode := RunCli(['build', SimpleFixture, '--output',
    SourceLinkOutputDirectory,
    '--repository-url=https://github.com/example/repo',
    '--source-link-template=blob/main/{path}#L{line}'], StdOut, StdErr);
  Expect('a complete source-link configuration should build', ExitCode = 0);
  Expect('source links should reach the generated pages',
    FileExists(SourceLinkOutputDirectory + '/html/units/SimpleUnit.html'));
end;

begin
  Failures := 0;
  RunCase('version and usage', @CheckVersionAndUsage);
  RunCase('usage errors', @CheckUsageErrors);
  RunCase('build and incremental parity', @CheckBuildAndIncremental);
  RunCase('failure policies', @CheckFailurePolicies);
  RunCase('source link validation', @CheckSourceLinkValidation);
  DeleteTree('build/cli-test');
  if Failures > 0 then
  begin
    WriteLn(StdErr, Failures, ' CLI test case(s) failed.');
    Halt(1);
  end;
  WriteLn('All PasWeave CLI tests passed.');
end.
