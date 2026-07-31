unit RelationshipImplementations;

{$mode objfpc}{$H+}

interface

uses
  RelationshipBase;

type
  TChild = class(TBase, IBase)
  end;

  TGrandChild = class(TChild, IExtended)
  end;

  generic TGenericChild<T> = class(specialize TGenericBase<T>, IExtended)
  end;

  TUnresolvedChild = class(TMissingBase)
  end;

  TUnscopedChild = class(TUnscopedBase)
  end;

  TChildAlias = TChild;

implementation

end.
