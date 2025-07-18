@echo off
color 0a
cd ..
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib git hxcpp https://github.com/kittycathy233/hxcpp --quiet
haxelib install lime 8.2.2 --quiet
haxelib install openfl 9.4.1 --quiet
haxelib install flixel 5.9.0 --quiet
haxelib install flixel-addons 3.3.2 --quiet
haxelib install flixel-tools 1.5.1 --quiet
haxelib install hscript-iris 1.1.3 --quiet
haxelib install tjson 1.4.0 --quiet
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e --quiet
haxelib git linc_luajit https://github.com/kittycathy233/linc_luajit --quiet
haxelib install hxdiscord_rpc --quiet --skip-dependencies
haxelib install hxvlc 2.0.1 --quiet --skip-dependencies
haxelib install flxgif 1.0.3 --quiet
haxelib install flxsvg 1.1.0 --quiet
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90 --quiet --skip-dependencies
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666 --quiet
echo Finished!
pause
