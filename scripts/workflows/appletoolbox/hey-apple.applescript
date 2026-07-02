-- Activate AppleToolbox — bring the live panel to the front (or launch it).
-- App: AppleToolbox
-- Triggers: hey apple, activate appletoolbox, apple toolbox, toolbox on, wake apple
-- Category: AppleToolbox
-- Usage: bound to the "Hey Apple" Vocal Shortcut in Accessibility → Voice Control
-- Wired to AppleToolbox.app --activate (which posts a DistributedNotification or
-- spawns a fresh --live instance if none is alive).

do shell script "open -b com.esaruoho.appletoolbox --args --activate"
