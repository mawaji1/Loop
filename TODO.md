# TODO

## Foodpicker

-  Bug: Undo carbs does not work with a weird healthd error.  Very similar
   code path seems to work fine in Carb Counteraction View Controller.
-  Bug: Undo possible even after bolus
-  Feature: Edit amount after the fact.
-  UI: Instead of carbs display selected quantity.

## Future Low Warning

-  Add different sounds depending on urgency of eating.
-  Use the same code path as the Bolus calculation.

## Activity

-  Feature: Log workout mode and disconnect as Exercise in Nightscout (requires
   tracking the ID of the event from Nightscout).

## QuickCarbEntry

-  UI: Display slider or wheel for carbs instead of text entry

## Safety Carbs-Entered / Considered limit.

-  Feature: could probably simplify to a warning threshold and refuse entry above a certain amount
   Not super important, as MaxIOB is doing the same thing essentially

## Consistent placement of "Save" button

-  Nit: currently 'Pick Food' is the only one with a button on the top right, should probably get one some at the bottom
        or Notes should have a save button on the top right.

## Bluetooth restart

-  Still needs a lot of testing and a way to trigger without Bluetooth packets.
-  February: Seems to work fine now.

## Foodmanager

-  Add dextrose tabs
-  Add ice cream
-  Reduce milk and chocolate default to 200 ml
-  Check if fries carbs are correct.


## Nightscout Logging

-  Limit backlog to prevent crashes in no connectivity situations.
