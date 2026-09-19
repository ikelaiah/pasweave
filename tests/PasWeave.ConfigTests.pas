unit PasWeave.ConfigTests;

{$mode objfpc}{$H+}{$J+}

interface

procedure RunConfigTests;

implementation

uses
  SysUtils, PasWeave.Comments, PasWeave.Config, PasWeave.Model,
  PasWeave.TestSupport;

const
  ConfigDirectory = 'build/config-test';

procedure WriteConfig(const AName, AJSON: string);
begin
  WriteTextFile(ConfigDirectory + '/' + AName, AJSON);
end;

procedure ExpectRejected(const AName, AJSON, AExpectedFragment: string);
var
  ErrorMessage: string;
begin
  WriteConfig(AName, AJSON);
  ErrorMessage := '';
  try
    LoadProjectConfig(ConfigDirectory + '/' + AName).Free;
  except
    on E: EProjectConfigError do
      ErrorMessage := E.Message;
  end;
  Check(ErrorMessage <> '', AName + ' should be rejected');
  Check(Pos(AExpectedFragment, ErrorMessage) > 0,
    AName + ' should explain the problem (got: ' + ErrorMessage + ')');
end;

procedure CheckValidConfiguration;
var
  Config: TProjectConfig;
begin
  WriteConfig('valid.json',
    '{' +
    '  "version": 1,' +
    '  "source": "src",' +
    '  "output": "build/docs",' +
    '  "comments": "slash, brace",' +
    '  "visibility": "all",' +
    '  "project": {' +
    '    "name": "Config Fixture",' +
    '    "mark": "CFG",' +
    '    "repositoryUrl": "https://github.com/example/project",' +
    '    "sourceLinkTemplate": "blob/main/{path}#L{line}",' +
    '    "theme": {' +
    '      "accent": "#123456",' +
    '      "accent2": "#abcdef",' +
    '      "font": "Avenir Next"' +
    '    }' +
    '  },' +
    '  "discovery": {' +
    '    "recursive": true,' +
    '    "include": ["src/**"],' +
    '    "exclude": ["generated/**", "vendor/**"]' +
    '  },' +
    '  "compiler": {' +
    '    "unitPaths": ["packages/core/src"],' +
    '    "includePaths": ["include"],' +
    '    "defines": ["USE_FAST_MATH"],' +
    '    "targetOs": "macOS",' +
    '    "targetCpu": "arm64",' +
    '    "buildMode": "Release",' +
    '    "packagePaths": ["packages"]' +
    '  },' +
    '  "coverage": {' +
    '    "minimum": 90,' +
    '    "failOn": "warning"' +
    '  }' +
    '}');
  Config := LoadProjectConfig(ConfigDirectory + '/valid.json');
  try
    Check(Config.SourcePath = 'src', 'source should be retained');
    Check(Config.OutputPath = 'build/docs', 'output should be retained');
    Check(Config.HasComments and (Config.Comments =
      [dcsSlash, dcsBrace]), 'comment styles should parse');
    Check(Config.Visibility = rvpAllDeclarations,
      'visibility "all" should select every declaration');
    Check(Config.ProjectName = 'Config Fixture', 'project name should parse');
    Check(Config.ProjectMark = 'CFG', 'project mark should parse');
    Check(Config.RepositoryURL = 'https://github.com/example/project',
      'repository URL should parse');
    Check(Config.SourceLinkTemplate = 'blob/main/{path}#L{line}',
      'source-link template should parse');
    Check((Config.ThemeAccent = '#123456') and
      (Config.ThemeAccentAlt = '#abcdef') and
      (Config.ThemeFont = 'Avenir Next'), 'theme tokens should parse');
    Check(Config.Recursive, 'recursive discovery should parse');
    Check((Config.IncludePatterns.Count = 1) and
      (Config.IncludePatterns[0] = 'src/**'), 'include globs should parse');
    Check((Config.ExcludePatterns.Count = 2) and
      (Config.ExcludePatterns[1] = 'vendor/**'), 'exclude globs should parse');
    Check((Config.UnitPaths.Count = 1) and
      (Config.UnitPaths[0] = 'packages/core/src'), 'unit paths should parse');
    Check((Config.IncludePaths.Count = 1) and
      (Config.IncludePaths[0] = 'include'), 'include paths should parse');
    Check((Config.Defines.Count = 1) and
      (Config.Defines[0] = 'USE_FAST_MATH'), 'defines should parse');
    Check((Config.TargetOS = 'darwin') and (Config.TargetCPU = 'aarch64'),
      'target aliases should normalize like the CLI');
    Check(Config.BuildMode = 'Release', 'build mode should parse');
    Check((Config.PackagePaths.Count = 1) and
      (Config.PackagePaths[0] = 'packages'), 'package paths should parse');
    Check(Config.HasMinimumCoverage and (Config.MinimumCoverage = 90),
      'coverage minimum should parse');
    Check(Config.FailOn = 'warning', 'failure threshold should parse');
  finally
    Config.Free;
  end;
end;

procedure CheckMinimalConfiguration;
var
  Config: TProjectConfig;
begin
  WriteConfig('minimal.json', '{"version": 1}');
  Config := LoadProjectConfig(ConfigDirectory + '/minimal.json');
  try
    Check((Config.SourcePath = '') and (Config.OutputPath = ''),
      'absent paths should stay empty for CLI defaults');
    Check(not Config.HasComments and (Config.Comments =
      DefaultDocumentationCommentStyles), 'absent comments should use default');
    Check(Config.Visibility = rvpPublicAPI,
      'absent visibility should use the public API policy');
    Check(not Config.HasMinimumCoverage, 'absent coverage should stay unset');
  finally
    Config.Free;
  end;
end;

procedure CheckRejectedConfigurations;
begin
  ExpectRejected('unknown-root.json',
    '{"version": 1, "sourcez": "src"}', 'unknown configuration key');
  ExpectRejected('unknown-nested.json',
    '{"version": 1, "project": {"naem": "x"}}',
    'unknown configuration key: project.naem');
  ExpectRejected('wrong-type.json', '{"version": 1, "source": 5}',
    'wrong type: source');
  ExpectRejected('missing-version.json', '{"source": "src"}',
    'missing the required version');
  ExpectRejected('future-version.json', '{"version": 2}',
    'unsupported configuration version');
  ExpectRejected('non-object-root.json', '[1, 2]',
    'root must be a JSON object');
  ExpectRejected('invalid-json.json', '{not json',
    'not valid JSON');
  ExpectRejected('absolute-path.json', '{"version": 1, "source": "/etc"}',
    'must be relative');
  ExpectRejected('traversal.json', '{"version": 1, "source": "../outside"}',
    'escapes the configuration directory');
  ExpectRejected('nested-traversal.json',
    '{"version": 1, "compiler": {"unitPaths": ["a/../../b"]}}',
    'escapes the configuration directory');
  ExpectRejected('empty-path.json', '{"version": 1, "output": ""}',
    'must not be empty');
  ExpectRejected('bad-comments.json', '{"version": 1, "comments": "stars"}',
    'not a supported comment style');
  ExpectRejected('bad-visibility.json', '{"version": 1, "visibility": "none"}',
    'must be "public" or "all"');
  ExpectRejected('bad-mark.json', '{"version": 1, "project": {"mark": "TOOLONG"}}',
    'mark must be 1 to 4 alphanumeric');
  ExpectRejected('bad-color.json',
    '{"version": 1, "project": {"theme": {"accent": "red"}}}',
    'accent must be a #RGB');
  ExpectRejected('bad-font.json',
    '{"version": 1, "project": {"theme": {"font": "x;}"}}}',
    'font must be a safe font family name');
  ExpectRejected('bad-target-os.json',
    '{"version": 1, "compiler": {"targetOs": "plan9"}}',
    'not a supported FPC target');
  ExpectRejected('bad-target-cpu.json',
    '{"version": 1, "compiler": {"targetCpu": "z80"}}',
    'not a supported FPC target');
  ExpectRejected('bad-define.json', '{"version": 1, "compiler": {"defines": ["2BAD"]}}',
    'plain Pascal identifier');
  ExpectRejected('bad-coverage.json', '{"version": 1, "coverage": {"minimum": 101}}',
    'integer from 0 to 100');
  ExpectRejected('bad-fail-on.json', '{"version": 1, "coverage": {"failOn": "info"}}',
    'must be warning or error');
  ExpectRejected('bad-glob.json',
    '{"version": 1, "discovery": {"exclude": ["../outside"]}}',
    'discovery include/exclude');
end;

procedure RunConfigTests;
begin
  BeginTest('project configuration');
  DeleteTree(ConfigDirectory);
  CheckValidConfiguration;
  CheckMinimalConfiguration;
  CheckRejectedConfigurations;
  DeleteTree(ConfigDirectory);
end;

end.
