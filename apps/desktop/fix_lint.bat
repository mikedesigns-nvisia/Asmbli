@echo off
echo Fixing common lint issues...

REM Fix prefer_const_constructors in key files
echo Applying dart fix --apply...
cd /d "C:\Asmbli\apps\desktop"
flutter packages pub run dart_fixer:fix --apply --fix-prefer-const-constructors

REM Alternative: Use dart fix
dart fix --apply

echo Lint fixes applied!
pause