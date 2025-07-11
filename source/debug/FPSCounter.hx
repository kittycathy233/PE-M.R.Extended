package debug;

import flixel.FlxG;
import openfl.Lib;
import haxe.Timer;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System as OpenFlSystem;
import lime.system.System as LimeSystem;
import states.MainMenuState;
import debug.GameVersion;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#else
@:headerInclude('sys/utsname.h')
#end
#end
class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;

	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var lastFramerateUpdateTime:Float;
	@:noCompletion private var updateTime:Int;
	@:noCompletion private var framesCount:Int;
	@:noCompletion private var prevTime:Int;

	public var os:String = '';

	public var drawTime:Float = 0;
	public var activeCount:Int = 0;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		#if !officialBuild
		if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end;
		else
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end + ' - ${LimeSystem.platformVersion}';
		#end

		positionFPS(x, y);

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		width = FlxG.width;
		multiline = true;
		text = "Loading... ";

		times = [];
		lastFramerateUpdateTime = Timer.stamp();
		prevTime = Lib.getTimer();
		updateTime = prevTime + 500;
		framesCount = 0;
	}


	public dynamic function updateText():Void // so people can override it in hscript
	{
		var fpsText = 'FPS: $currentFPS\nMemory: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)}';
        var infoText = '';
        if(ClientPrefs.data.exgameversion) {
            infoText = '\nPsych Engine v${MainMenuState.psychEngineVersion}'
                    + '\nMintRhythm Extended v${MainMenuState.mrExtendVersion}'
                    + '\nCommit: ${GameVersion.getGitCommitCount()} (${GameVersion.getGitCommitHash()})'
					+ '\nUpdate: ${updateTime}ms (${activeCount} objs loaded)'
					+ '\nFPS Mode: ${ClientPrefs.data.fpsRework ? "Rework" : "Legacy"}'; // 添加FPS模式显示
        }
        
        if(ClientPrefs.data.showRunningOS) infoText += os;

        var isBottom = ClientPrefs.data.fpsPosition.indexOf("BOTTOM") != -1;
        text = isBottom ? infoText + "\n" + fpsText : fpsText + infoText;

        textColor = 0xFFFFFFFF;
        if (currentFPS < FlxG.stage.window.frameRate * 0.5)
            textColor = 0xFFFF0000;
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		// 统一使用更精确的FPS计算方式
		var currentTime = openfl.Lib.getTimer();
		framesCount++;
		
		if (currentTime >= updateTime) {
			var elapsed = currentTime - prevTime;
			currentFPS = Math.ceil((framesCount * 1000) / elapsed);
			framesCount = 0;
			prevTime = currentTime;
			updateTime = currentTime + 500;
		}
		
		// 仅在传统模式下检查并更新Flixel帧率
		if (!ClientPrefs.data.fpsRework) {
			// 防止Flixel帧率设置被意外改变
			if (FlxG.updateFramerate != ClientPrefs.data.framerate ||
				FlxG.drawFramerate != ClientPrefs.data.framerate) {
				FlxG.updateFramerate = ClientPrefs.data.framerate;
				FlxG.drawFramerate = ClientPrefs.data.framerate;
			}
		}
		
		updateText();
	}

	inline function get_memoryMegas():Float
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1)
	{
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
		
        var spacing = ClientPrefs.data.fpsSpacing;
        var isRight = ClientPrefs.data.fpsPosition.indexOf("RIGHT") != -1;
        var isBottom = ClientPrefs.data.fpsPosition.indexOf("BOTTOM") != -1;
        
        // Set text alignment
        autoSize = isRight ? RIGHT : LEFT;
        
        // Position the counter
        if(isRight) {
            x = FlxG.game.x + FlxG.width - width - spacing;
        } else {
            x = FlxG.game.x + spacing;
        }
        
        if(isBottom) {
            y = FlxG.game.y + FlxG.height - height - spacing;
        } else {
            y = FlxG.game.y + spacing;
        }
	}

	#if cpp
	#if windows
	@:functionCode('
		SYSTEM_INFO osInfo;

		GetSystemInfo(&osInfo);

		switch(osInfo.wProcessorArchitecture)
		{
			case 9:
				return ::String("x86_64");
			case 5:
				return ::String("ARM");
			case 12:
				return ::String("ARM64");
			case 6:
				return ::String("IA-64");
			case 0:
				return ::String("x86");
			default:
				return ::String("Unknown");
		}
	')
	#elseif (ios || mac)
	@:functionCode('
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
    	return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
	')
	#else
	@:functionCode('
		struct utsname osInfo{};
		uname(&osInfo);
		return ::String(osInfo.machine);
	')
	#end
	@:noCompletion
	private function getArch():String
	{
		return "Unknown";
	}
	#end
}