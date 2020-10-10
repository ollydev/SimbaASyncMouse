library libasyncmouse;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cmem, cthreads,
  {$ENDIF}
  classes, sysutils,
  libasyncmouse.asyncmouse;

{$i simbaplugin.inc}

type
  PASyncMouse = ^TASyncMouse;
  TASyncMouse = packed record
    Thread: TASyncMouseThread;
    Speed: Int32;
    Wind: Double;
    Gravity: Double;
  end;

procedure Lape_ASyncMouse_Create(const Params: PParamArray; const Result: Pointer); cdecl;
var
  Mouse: PASyncMouse absolute Result;
begin
  Mouse^.Thread := TASyncMouseThread.Create(TASyncMouse_Teleport(PPointer(Params^[0])^), TASyncMouse_GetPosition(PPointer(Params^[1])^));

  // Default values (ame as SRL)
  Mouse^.Speed := 12;
  Mouse^.Gravity := 9;
  Mouse^.Wind := 5;
end;

procedure Lape_ASyncMouse_Free(const Params: PParamArray); cdecl;
begin
  PASyncMouse(Params^[0])^.Thread.Free();
end;

procedure Lape_ASyncMouse_Move(const Params: PParamArray); cdecl;
var
  Mouse: PASyncMouse;
  Destination: TPoint;
  Accuracy: Double;
begin
  Mouse := PASyncMouse(Params^[0]);
  Destination := TPoint(Params^[1]^);
  Accuracy := PDouble(Params^[2])^;

  with Mouse^ do
    Thread.Move(Destination, Speed, Gravity, Wind, Accuracy);
end;

procedure Lape_ASyncMouse_ChangeDestination(const Params: PParamArray); cdecl;
begin
  PASyncMouse(Params^[0])^.Thread.Destination := TPoint(Params^[1]^);
end;

procedure Lape_ASyncMouse_IsMoving(const Params: PParamArray; const Result: Pointer); cdecl;
begin
  PBoolean(Result)^ := PASyncMouse(Params^[0])^.Thread.Moving;
end;

procedure Lape_ASyncMouse_Stop(const Params: PParamArray); cdecl;
begin
  PASyncMouse(Params^[0])^.Thread.Moving := False;
end;

procedure Lape_ASyncMouse_WaitMoving(const Params: PParamArray); cdecl;
begin
  PASyncMouse(Params^[0])^.Thread.WaitMoving();
end;

begin
  addGlobalType('packed record      ' + LineEnding +
                '  Thread: Pointer; ' + LineEnding +
                '  Speed: Int32;    ' + LineEnding +
                '  Wind: Double;    ' + LineEnding +
                '  Gravity: Double; ' + LineEnding +
                'end;',
                'TASyncMouse');

  addGlobalFunc('function TASyncMouse.Create(Teleport: native(type procedure(X, Y: Int32)); GetPosition: native(type function(): TPoint)): TASyncMouse; static; native;', @Lape_ASyncMouse_Create);
  addGlobalFunc('procedure TASyncMouse.Free; native;', @Lape_ASyncMouse_Free);
  addGlobalFunc('procedure TASyncMouse.Move(Destination: TPoint; Accuracy: Double = 1); native;', @Lape_ASyncMouse_Move);
  addGlobalFunc('procedure TASyncMouse.ChangeDestination(Destination: TPoint); native;', @Lape_ASyncMouse_ChangeDestination);
  addGlobalFunc('procedure TASyncMouse.Stop; native;', @Lape_ASyncMouse_Stop);
  addGlobalFunc('procedure TASyncMouse.WaitMoving; native;', @Lape_ASyncMouse_WaitMoving);
  addGlobalFunc('function TASyncMouse.IsMoving: Boolean; native;', @Lape_ASyncMouse_IsMoving);

  addCode('procedure TASyncMouse.Teleport(X, Y: Int32); static;'                                           + LineEnding +
          'begin'                                                                                          + LineEnding +
          '  MoveMouse(X, Y);'                                                                             + LineEnding +
          'end;'                                                                                           + LineEnding +
          ''                                                                                               + LineEnding +
          'function TASyncMouse.Position: TPoint; static;'                                                 + LineEnding +
          'begin'                                                                                          + LineEnding +
          '  GetMousePos(Result.X, Result.Y);'                                                             + LineEnding +
          'end;'                                                                                           + LineEnding +
          ''                                                                                               + LineEnding +
          'var'                                                                                            + LineEnding +
          '  ASyncMouse: TASyncMouse := TASyncMouse.Create(@TASyncMouse.Teleport, @TASyncMouse.Position);' + LineEnding +
          'begin'                                                                                          + LineEnding +
          '  AddOnTerminate(@ASyncMouse.Free);'                                                            + LineEnding +
          'end;');
end.
