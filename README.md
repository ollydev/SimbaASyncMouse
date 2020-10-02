## ASyncMouse

This is a Simba plugin which moves the mouse on another thread so your script can continue doing things while the mouse is moving.

### Usage:
`{$loadlib libasyncmouse}` will provide an `ASyncMouse` variable with the following methods and variables available:
```pascal
procedure TASyncMouse.Move(Destination: TPoint; Accuracy: Double = 1);
procedure TASyncMouse.ChangeDestination(Destination: TPoint);
procedure TASyncMouse.Stop;
procedure TASyncMouse.WaitMoving;
function TASyncMouse.IsMoving: Boolean;
```
```pascal
ASyncMouse.Speed := 6;
ASyncMouse.Gravity := 10;
ASyncMouse.Wind := 8;
```
---

For example while the mouse is moving you can find an object and update the destination.

```pascal
function FindMyObject(out Position: TPoint): Boolean;
begin
  // Your object finder ..
end;

var
  Position: TPoint;

begin
  if FindMyObject(Position) then
  begin
    ASyncMouse.Move(Position);

    while ASyncMouse.IsMoving() do
    begin
      if FindMyObject(Position) then
        ASyncMouse.ChangeDestination(Position);

      Wait(50);
    end;
  end;
end.
```
---
Algorithm used for mouse movement: https://github.com/BenLand100/SMART/blob/master/src/EventNazi.java#L201