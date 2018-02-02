# TODO

## QuickCarbEntry

-  Manual Glucose Entry (plus LoopManager handling if necessary)
-  Display slider or wheel for carbs instead of text entry


## Safety Carbs-Entered / Considered limit.

- could probably simplify to a warning threshold and refuse entry above a certain amount
- Not super important, as MaxIOB is doing the same thing essentially

## Consistent placement of "Save" button

- currently 'Pick Food' is the only one with a button on the top right, should probably get one some at the bottom
  or Notes should have a save button on the top right.

## Revisit Insulinmodel Settings

- activity 300, peak 50 was the old model


## Logging

-  number log entries and add uuid. - done
-  log entries still missing, not sure where and why

## Bluetooth restart

-  trigger on rileylink but no glucose. - need to test


## Foodmanager

-  add dextrose tabs
-  reduce milk and chocolate to 200 ml
-  Undo possible even after bolus
-  Undo not working properly. At least propagate error.
-  Sometimes after lock screen the mealInformation is out of date -> move to view controller logic.
