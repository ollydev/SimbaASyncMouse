unit libasyncmouse.asyncmouse;

{$mode objfpc}{$H+}

interface

uses
  classes, sysutils, syncobjs;

type
  TASyncMouse_Teleport = procedure(X, Y: Int32);
  TASyncMouse_GetPosition = function(): TPoint;

  TASyncMouseThread = class(TThread)
  protected
    FEvent: TSimpleEvent;
    FTeleport: TASyncMouse_Teleport;
    FGetPosition: TASyncMouse_GetPosition;
    FPosition: TPoint;
    FDestination: TPoint;
    FGravity: Double;
    FWind: Double;
    FMinWait: Double;
    FMaxWait: Double;
    FMaxStep: Double;
    FTargetArea: Double;
    FAccuracy: Double;
    FMoving: Boolean;

    procedure Execute; override;
  public
    procedure Move(Destination: TPoint; Speed, Gravity, Wind, Accuracy: Double);

    procedure WaitMoving;

    property Destination: TPoint read FDestination write FDestination;
    property Moving: Boolean read FMoving write FMoving;

    constructor Create(Teleport: TASyncMouse_Teleport; GetPosition: TASyncMouse_GetPosition);
    destructor Destroy; override;
  end;

implementation

uses
  math;

function nzRandom: Extended;
begin
  {$IFDEF FPC_HAS_TYPE_EXTENDED}
  Result := Max(Random(), 1.0e-4900);
  {$ELSE}
  Result := Max(Random(), 1.0e-320);
  {$ENDIF}
end;

function TruncatedGauss(Left: Double = 0; Right: Double = 1; CUTOFF: Single = 4): Double;
begin
  Result := CUTOFF + 1;
  while Result >= CUTOFF do
    Result := Abs(Sqrt(-2 * Ln(nzRandom())) * Cos(2 * PI * Random()));
  Result := Result / CUTOFF * (Right-Left) + Left;
end;

procedure TASyncMouseThread.Execute;

  // https://github.com/BenLand100/SMART/blob/master/src/EventNazi.java#L201
  procedure WindMouse(var Moving: Boolean; Position: TPoint; var Destination: TPoint; Gravity, Wind, MinWait, MaxWait, MaxStep, TargetArea, Accuracy: Double);
  var
    x, y: Double;
    veloX, veloY, windX, windY, veloMag, randomDist, step, idle: Double;
    traveledDistance, remainingDistance: Double;
    t: UInt64;
  begin
    windX := 0;
    windY := 0;
    veloX := 0;
    veloY := 0;

    x := Position.X;
    y := Position.Y;

    t := GetTickCount();

    while Moving do
    begin
      if GetTickCount() > t + 15000 then
      begin
        WriteLn('Something went wrong. AsyncMouse movement did not complete in 15 seconds.');
        Break;
      end;

      traveledDistance := Hypot(x - Position.X, y - Position.Y);
      remainingDistance := Hypot(x - Destination.X, y - Destination.Y);
      if (remainingDistance <= Max(1, Accuracy)) then
        Break;

      wind := Min(wind, remainingDistance);
      windX := windX / sqrt(3) + (Random(Round(wind) * 2 + 1) - wind) / sqrt(5);
      windY := windY / sqrt(3) + (Random(Round(wind) * 2 + 1) - wind) / sqrt(5);

      if (remainingDistance < targetArea) then
        step := (remainingDistance / 2) + (Random() * 6 - 3)
      else
      if (traveledDistance < targetArea) then
      begin
        if (traveledDistance < 3) then
          traveledDistance := 10 * Random();

        step := traveledDistance * (1 + Random() * 3);
      end else
        step := maxStep;

      step := Min(step, maxStep);
      if (step < 3) then
        step := 3 + (Random() * 3);

      veloX := veloX + windX;
      veloY := veloY + windY;
      veloX := veloX + gravity * (Destination.X - x) / remainingDistance;
      veloY := veloY + gravity * (Destination.Y - y) / remainingDistance;

      if (Hypot(veloX, veloY) > step) then
      begin
        randomDist := step / 3.0 + (step / 2 * Random());

        veloMag := sqrt(veloX * veloX + veloY * veloY);
        veloX := (veloX / veloMag) * randomDist;
        veloY := (veloY / veloMag) * randomDist;
      end;

      idle := (maxWait - minWait) * (Hypot(veloX, veloY) / maxStep) + minWait;

      x := x + veloX;
      y := y + veloY;

      FTeleport(Round(x), Round(y));

      Sleep(Round(idle));
    end;

    if Moving then
    begin
      if (Accuracy = 1) then
        FTeleport(Destination.X, Destination.Y);

      Moving := False;
    end;
  end;

begin
  while (not Terminated) do
  begin
    if FEvent.WaitFor(1000) = wrSignaled then
      WindMouse(FMoving, FPosition, FDestination, FGravity, FWind, FMinWait, FMaxWait, FMaxStep, FTargetArea, FAccuracy);

    FEvent.ResetEvent();
  end;
end;

procedure TASyncMouseThread.Move(Destination: TPoint; Speed, Gravity, Wind, Accuracy: Double);
var
  Exponential: Double;
begin
  while FMoving do
    Sleep(20);

  FPosition := FGetPosition();

  Exponential := Power(Hypot(FPosition.X - Destination.X, FPosition.Y - Destination.Y), 0.33) / 10;

  Speed := TruncatedGauss(Speed, Speed * 1.5);
  Speed *= Exponential;
  Speed /= 10;

  FDestination := Destination;
  FGravity := Gravity;
  FWind := Wind;
  FMinWait := 5 / Speed;
  FMaxWait := 10 / Speed;
  FMaxStep := 20 * Speed;
  FTargetArea := 20 * Speed;
  FAccuracy := Accuracy;
  FMoving := True;

  FEvent.SetEvent();
end;

procedure TASyncMouseThread.WaitMoving;
begin
  while FMoving do
    Sleep(25);
end;

constructor TASyncMouseThread.Create(Teleport: TASyncMouse_Teleport; GetPosition: TASyncMouse_GetPosition);
begin
  inherited Create(False);

  FTeleport := Teleport;
  FGetPosition := GetPosition;
  FEvent := TSimpleEvent.Create();
end;

destructor TASyncMouseThread.Destroy;
begin
  Terminate();
  WaitFor();

  FEvent.Free();

  inherited Destroy();
end;

initialization
  Randomize();

end.

