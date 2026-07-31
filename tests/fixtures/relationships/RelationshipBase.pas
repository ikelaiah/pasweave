unit RelationshipBase;

{$mode objfpc}{$H+}

interface

type
  IBase = interface
  end;

  IExtended = interface(IBase)
  end;

  TBase = class
  end;

  generic TGenericBase<T> = class(TBase)
  end;

implementation

end.
