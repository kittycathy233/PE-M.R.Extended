package options;

import backend.StageData;
import objects.Character;
import objects.Bar;
import flixel.addons.display.shapes.FlxShapeCircle;

import states.stages.StageWeek1 as BackgroundStage;

class NoteOffsetState extends MusicBeatState
{
	var stageDirectory:String = 'week1';
	var boyfriend:Character;
	var gf:Character;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	var coolText:FlxText;
	var rating:FlxSprite;
	var comboNums:FlxSpriteGroup;
	var dumbTexts:FlxTypedGroup<FlxText>;

	//新东西
	var theEXrating:FlxSprite;
	public var scoreTxt:FlxText;
	var scoreTxtTween:FlxTween;
	public var health:Float = 1;
	public var healthBar:Bar;

	var barPercent:Float = 0;
	var delayMin:Int = -500;
	var delayMax:Int = 500;
	var timeBar:Bar;
	var timeTxt:FlxText;
	var beatText:Alphabet;
	var beatTween:FlxTween;

	var changeModeText:FlxText;

	var controllerPointer:FlxSprite;
	var _lastControllerMode:Bool = false;

	override public function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Delay/Combo Offset Menu", null);
		#end

		// Cameras
		camGame = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther, false);

		FlxG.camera.scroll.set(120, 130);

		persistentUpdate = true;
		FlxG.sound.pause();

		// Stage
		Paths.setCurrentLevel(stageDirectory);
		new BackgroundStage();

		// Characters
		gf = new Character(400, 130, 'gf');
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
		gf.scrollFactor.set(0.95, 0.95);
		boyfriend = new Character(770, 100, 'bf', true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(gf);
		add(boyfriend);

		// Combo stuff
		coolText = new FlxText(0, 0, 0, '', 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;

		//rating = new FlxSprite().loadGraphic(Paths.image('sick'));
		if(!ClientPrefs.data.rmPerfect)
			{
				theEXrating = new FlxSprite().loadGraphic(Paths.image('perfect-extra'));
				rating = new FlxSprite().loadGraphic(Paths.image('perfect'));
			} else {
				theEXrating = new FlxSprite().loadGraphic(Paths.image('sick-extra'));
				rating = new FlxSprite().loadGraphic(Paths.image('sick'));
			}
		rating.cameras = [camHUD];
		rating.antialiasing = ClientPrefs.data.antialiasing;
		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		
		add(rating);

		theEXrating.cameras = [camHUD];
		theEXrating.setGraphicSize(Std.int(theEXrating.width * 0.65));
		theEXrating.updateHitbox();
		theEXrating.antialiasing = ClientPrefs.data.antialiasing;

		if(ClientPrefs.data.exratingDisplay) add(theEXrating);

		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		add(healthBar);

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "Score: 1145140 | Misses: 191 | Rating: Great (81%)", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);

		comboNums = new FlxSpriteGroup();
		comboNums.cameras = [camHUD];
		add(comboNums);

		var seperatedScore:Array<Int> = [];
		for (i in 0...3)
		{
			seperatedScore.push(FlxG.random.int(0, 9));
		}

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite(43 * daLoop).loadGraphic(Paths.image('num' + i));
			numScore.cameras = [camHUD];
			numScore.antialiasing = ClientPrefs.data.antialiasing;
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();
			comboNums.add(numScore);
			daLoop++;
		}

		dumbTexts = new FlxTypedGroup<FlxText>();
		dumbTexts.cameras = [camHUD];
		add(dumbTexts);
		createTexts();

		repositionCombo();

		// Note delay stuff
		beatText = new Alphabet(0, 0, LanguageBasic.getPhrase('delay_beat_hit', 'Beat Hit!'), true);
		beatText.setScale(0.6, 0.6);
		beatText.x += 260;
		beatText.alpha = 0;
		beatText.acceleration.y = 250;
		beatText.visible = false;
		add(beatText);
		
		timeTxt = new FlxText(0, 600, FlxG.width, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.borderSize = 2;
		timeTxt.visible = false;
		timeTxt.cameras = [camHUD];

		barPercent = ClientPrefs.data.noteOffset;
		updateNoteDelay();
		
		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 3), 'healthBar', function() return barPercent, delayMin, delayMax);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.visible = false;
		timeBar.cameras = [camHUD];
		timeBar.leftBar.color = FlxColor.LIME;

		add(timeBar);
		add(timeTxt);

		///////////////////////

		var blackBox:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 40, FlxColor.BLACK);
		blackBox.scrollFactor.set();
		blackBox.alpha = 0.6;
		blackBox.cameras = [camHUD];
		add(blackBox);

		changeModeText = new FlxText(0, 4, FlxG.width, "", 32);
		changeModeText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		changeModeText.scrollFactor.set();
		changeModeText.cameras = [camHUD];
		add(changeModeText);
		
		controllerPointer = new FlxShapeCircle(0, 0, 20, {thickness: 0}, FlxColor.WHITE);
		controllerPointer.offset.set(20, 20);
		controllerPointer.screenCenter();
		controllerPointer.alpha = 0.6;
		controllerPointer.cameras = [camHUD];
		add(controllerPointer);
		
		updateMode();
		_lastControllerMode = true;

		Conductor.bpm = 128.0;
		FlxG.sound.playMusic(Paths.music('offsetSong'), 1, true);

		// 根据设置调整图层
		updateRatingsPosition();

		super.create();
	}

	public function updateRatingsPosition()
	{
		var targetCamera:Array<FlxCamera> = ClientPrefs.data.ratingsPos == "camGame" ? [camGame] : [camHUD];

		// 更新 rating 和 theEXrating 的图层
		if (rating != null) rating.cameras = targetCamera;
		if (theEXrating != null) theEXrating.cameras = targetCamera;

		// 更新 comboNums 的图层
		comboNums.cameras = targetCamera;
	}

	var holdTime:Float = 0;
	var onComboMenu:Bool = true;
	var holdingObjectType:Null<Bool> = null;
	var theEXratingDrag:Null<Bool> = null;

	var startMousePos:FlxPoint = new FlxPoint();
	var startComboOffset:FlxPoint = new FlxPoint();

	override public function update(elapsed:Float)
	{
		var addNum:Int = 1;
		if(FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER))
		{
			if(onComboMenu)
				addNum = 10;
			else
				addNum = 3;
		}

		if(FlxG.gamepads.anyJustPressed(ANY)) controls.controllerMode = true;
		else if(FlxG.mouse.justPressed) controls.controllerMode = false;

		if(controls.controllerMode != _lastControllerMode)
		{
			//trace('changed controller mode');
			FlxG.mouse.visible = !controls.controllerMode;
			controllerPointer.visible = controls.controllerMode;

			// changed to controller mid state
			if(controls.controllerMode)
			{
				var mousePos = FlxG.mouse.getScreenPosition(camHUD);
				controllerPointer.x = mousePos.x;
				controllerPointer.y = mousePos.y;
			}
			updateMode();
			_lastControllerMode = controls.controllerMode;
		}

		if(onComboMenu)
		{
			if(FlxG.keys.justPressed.ANY || FlxG.gamepads.anyJustPressed(ANY))
			{
				var controlArray:Array<Bool> = null;
				if(!controls.controllerMode)
				{
					controlArray = [
						FlxG.keys.justPressed.LEFT,
						FlxG.keys.justPressed.RIGHT,
						FlxG.keys.justPressed.UP,
						FlxG.keys.justPressed.DOWN,
					
						FlxG.keys.justPressed.A,
						FlxG.keys.justPressed.D,
						FlxG.keys.justPressed.W,
						FlxG.keys.justPressed.S,

						FlxG.keys.justPressed.J,
						FlxG.keys.justPressed.L,
						FlxG.keys.justPressed.I,
						FlxG.keys.justPressed.K
					];
				}
				else
				{
					controlArray = [
						FlxG.gamepads.anyJustPressed(DPAD_LEFT),
						FlxG.gamepads.anyJustPressed(DPAD_RIGHT),
						FlxG.gamepads.anyJustPressed(DPAD_UP),
						FlxG.gamepads.anyJustPressed(DPAD_DOWN),
					
						FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_LEFT),
						FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_RIGHT),
						FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_UP),
						FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_DOWN)
					];
				}

				if(controlArray.contains(true))
				{
					for (i in 0...controlArray.length)
					{
						if(controlArray[i])
						{
							switch(i)
							{
								case 0:
									ClientPrefs.data.comboOffset[0] -= addNum;
								case 1:
									ClientPrefs.data.comboOffset[0] += addNum;
								case 2:
									ClientPrefs.data.comboOffset[1] += addNum;
								case 3:
									ClientPrefs.data.comboOffset[1] -= addNum;
								case 4:
									ClientPrefs.data.comboOffset[2] -= addNum;
								case 5:
									ClientPrefs.data.comboOffset[2] += addNum;
								case 6:
									ClientPrefs.data.comboOffset[3] += addNum;
								case 7:
									ClientPrefs.data.comboOffset[3] -= addNum;
								case 8:
									ClientPrefs.data.comboOffset[4] -= addNum;
								case 9:
									ClientPrefs.data.comboOffset[4] += addNum;
								case 10:
									ClientPrefs.data.comboOffset[5] += addNum;
								case 11:
									ClientPrefs.data.comboOffset[5] -= addNum;
							}
						}
					}
					repositionCombo();
				}
			}
			
			// controller things
			var analogX:Float = 0;
			var analogY:Float = 0;
			var analogMoved:Bool = false;
			var gamepadPressed:Bool = false;
			var gamepadReleased:Bool = false;
			if(controls.controllerMode)
			{
				for (gamepad in FlxG.gamepads.getActiveGamepads())
				{
					analogX = gamepad.getXAxis(LEFT_ANALOG_STICK);
					analogY = gamepad.getYAxis(LEFT_ANALOG_STICK);
					analogMoved = (analogX != 0 || analogY != 0);
					if(analogMoved) break;
				}
				controllerPointer.x = Math.max(0, Math.min(FlxG.width, controllerPointer.x + analogX * 1000 * elapsed));
				controllerPointer.y = Math.max(0, Math.min(FlxG.height, controllerPointer.y + analogY * 1000 * elapsed));
				gamepadPressed = !FlxG.gamepads.anyJustPressed(START) && controls.ACCEPT;
				gamepadReleased = !FlxG.gamepads.anyJustReleased(START) && controls.justReleased('accept');
			}
			//

			// probably there's a better way to do this but, oh well.
			if (FlxG.mouse.justPressed || gamepadPressed)
				{
					holdingObjectType = null;
					theEXratingDrag = null;
	
					if(!controls.controllerMode)
						FlxG.mouse.getScreenPosition(camHUD, startMousePos);
					else
						controllerPointer.getScreenPosition(startMousePos, camHUD);
	
					if (startMousePos.x - comboNums.x >= 0 && startMousePos.x - comboNums.x <= comboNums.width &&
						startMousePos.y - comboNums.y >= 0 && startMousePos.y - comboNums.y <= comboNums.height)
					{
						holdingObjectType = true;
						startComboOffset.x = ClientPrefs.data.comboOffset[2];
						startComboOffset.y = ClientPrefs.data.comboOffset[3];
						//trace('yo bro');
					}
					else if (startMousePos.x - rating.x >= 0 && startMousePos.x - rating.x <= rating.width &&
							 startMousePos.y - rating.y >= 0 && startMousePos.y - rating.y <= rating.height)
					{
						holdingObjectType = false;
						startComboOffset.x = ClientPrefs.data.comboOffset[0];
						startComboOffset.y = ClientPrefs.data.comboOffset[1];
						//trace('heya');
					}
					else if (startMousePos.x - theEXrating.x >= 0 && startMousePos.x - theEXrating.x <= theEXrating.width &&
							startMousePos.y - theEXrating.y >= 0 && startMousePos.y - theEXrating.y <= theEXrating.height)
					{
						theEXratingDrag = false;
						startComboOffset.x = ClientPrefs.data.comboOffset[4];
						startComboOffset.y = ClientPrefs.data.comboOffset[5];
					}
					
				}
	
				if(FlxG.mouse.justReleased || gamepadReleased) {
					holdingObjectType = null;
					theEXratingDrag = null;
					//trace('dead');
				}

			if(holdingObjectType != null)
			{
				if(FlxG.mouse.justMoved || analogMoved)
				{
					var mousePos:FlxPoint = null;
					if(!controls.controllerMode)
						mousePos = FlxG.mouse.getScreenPosition(camHUD);
					else
						mousePos = controllerPointer.getScreenPosition(camHUD);

					var addNum:Int = holdingObjectType ? 2 : 0;
					ClientPrefs.data.comboOffset[addNum + 0] = Math.round((mousePos.x - startMousePos.x) + startComboOffset.x);
					ClientPrefs.data.comboOffset[addNum + 1] = -Math.round((mousePos.y - startMousePos.y) - startComboOffset.y);
					repositionCombo();
				}
			}
			if(theEXratingDrag != null)
			{
				if(FlxG.mouse.justMoved)
				{
					var mmousePos:FlxPoint = FlxG.mouse.getScreenPosition(camHUD);
					var addNumm:Int = theEXratingDrag ? 0 : 0;
					ClientPrefs.data.comboOffset[addNumm + 4] = Math.round((mmousePos.x - startMousePos.x) + startComboOffset.x);
					ClientPrefs.data.comboOffset[addNumm + 5] = -Math.round((mmousePos.y - startMousePos.y) - startComboOffset.y);
					repositionCombo();
				}
			}
			if(controls.RESET || touchPad.buttonC.justPressed)
			{
				for (i in 0...ClientPrefs.data.comboOffset.length)
				{
					ClientPrefs.data.comboOffset[i] = 0;
				}
				repositionCombo();
			}
		}
		else
		{
			if(controls.UI_LEFT_P)
			{
				holdTime = 0;
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.data.noteOffset - 1, delayMax));
				updateNoteDelay();
			}
			else if(controls.UI_RIGHT_P)
			{
				holdTime = 0;
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.data.noteOffset + 1, delayMax));
				updateNoteDelay();
			}

			var mult:Int = 1;
			if(controls.UI_LEFT || controls.UI_RIGHT)
			{
				holdTime += elapsed;
				if(controls.UI_LEFT) mult = -1;
			}

			if(holdTime > 0.5)
			{
				barPercent += 100 * addNum * elapsed * mult;
				barPercent = Math.max(delayMin, Math.min(barPercent, delayMax));
				updateNoteDelay();
			}

			if(controls.RESET || touchPad.buttonC.justPressed)
			{
				holdTime = 0;
				barPercent = 0;
				updateNoteDelay();
			}
		}

		if((!controls.controllerMode && controls.ACCEPT) ||
		(controls.controllerMode && FlxG.gamepads.anyJustPressed(START)))
		{
			onComboMenu = !onComboMenu;
			updateMode();
		}

		if(controls.BACK)
		{
			if(zoomTween != null) zoomTween.cancel();
			if(beatTween != null) beatTween.cancel();

			persistentUpdate = false;
			MusicBeatState.switchState(new options.OptionsState());
			if(OptionsState.onPlayState)
			{
				if(ClientPrefs.data.pauseMusic != 'None')
					FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));
				else
					FlxG.sound.music.volume = 0;
			}
			else FlxG.sound.playMusic(Paths.music('freakyMenu'));
			FlxG.mouse.visible = false;
		}

		Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);
	}

	var zoomTween:FlxTween;
	var lastBeatHit:Int = -1;
	override public function beatHit()
	{
		super.beatHit();

		if(lastBeatHit == curBeat)
		{
			return;
		}

		if(curBeat % 2 == 0)
		{
			boyfriend.dance();
			gf.dance();
		}
		
		if(curBeat % 4 == 2)
		{
			FlxG.camera.zoom = 1.15;

			if(zoomTween != null) zoomTween.cancel();
			zoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, 1, {ease: FlxEase.circOut, onComplete: function(twn:FlxTween)
				{
					zoomTween = null;
				}
			});

			beatText.alpha = 1;
			beatText.y = 320;
			beatText.velocity.y = -150;
			if(beatTween != null) beatTween.cancel();
			beatTween = FlxTween.tween(beatText, {alpha: 0}, 1, {ease: FlxEase.sineIn, onComplete: function(twn:FlxTween)
				{
					beatTween = null;
				}
			});

			if(ClientPrefs.data.ratbounce == true) {
				rating.scale.set(0.8, 0.8);
				FlxTween.tween(rating.scale, {x: 0.7, y: 0.7}, 0.4, {ease: FlxEase.circOut,});
			}

			if(ClientPrefs.data.exratbounce == true) {
				theEXrating.scale.set(0.85, 0.85);
				theEXrating.angle = (Math.random() * 10 + 4) * (Math.random() > .5 ? 1 : -1);
				FlxTween.tween(theEXrating, {angle: 0}, .6, {ease: FlxEase.quartOut});
				FlxTween.tween(theEXrating.scale, {x: 0.7, y: 0.7}, 0.5, {ease: FlxEase.circOut});
			}
		}

		lastBeatHit = curBeat;
	}

	function repositionCombo()
	{
		rating.screenCenter();
		rating.x = coolText.x - 40 + ClientPrefs.data.comboOffset[0];
		rating.y -= 60 + ClientPrefs.data.comboOffset[1] - 100;

		comboNums.screenCenter();
		comboNums.x = coolText.x - 90 + ClientPrefs.data.comboOffset[2];
		comboNums.y += 80 - ClientPrefs.data.comboOffset[3] + 80;
		
		theEXrating.screenCenter();
		theEXrating.x = coolText.x - 40 + ClientPrefs.data.comboOffset[4] - 170;
		theEXrating.y += 0 - ClientPrefs.data.comboOffset[5] + 80;
		
		reloadTexts();
	}

	function createTexts()
	{
		for (i in 0...6)
		{
			var text:FlxText = new FlxText(10, 48 + (i * 30), 0, '', 24);
			text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 2;
			dumbTexts.add(text);
			text.cameras = [camHUD];

			if(i > 1)
			{
				text.y += 24;
			}
		}
	}

	function reloadTexts()
	{
		for (i in 0...dumbTexts.length)
		{
			switch(i)
			{
				case 0: dumbTexts.members[i].text = LanguageBasic.getPhrase('combo_rating_offset', 'Rating Offset:');
				case 1: dumbTexts.members[i].text = '[' + ClientPrefs.data.comboOffset[0] + ', ' + ClientPrefs.data.comboOffset[1] + ']';
				case 2: dumbTexts.members[i].text = LanguageBasic.getPhrase('combo_numbers_offset', 'Numbers Offset:');
				case 3: dumbTexts.members[i].text = '[' + ClientPrefs.data.comboOffset[2] + ', ' + ClientPrefs.data.comboOffset[3] + ']';
				case 4: dumbTexts.members[i].text = 'Extra Rating Offset:';
				case 5: dumbTexts.members[i].text = '[' + ClientPrefs.data.comboOffset[4] + ', ' + ClientPrefs.data.comboOffset[5] + ']';
			}
		}
	}

	function updateNoteDelay()
	{
		ClientPrefs.data.noteOffset = Math.round(barPercent);
		timeTxt.text = LanguageBasic.getPhrase('delay_current_offset', 'Current offset: {1} ms', [Math.floor(barPercent)]);
	}

	function updateMode()
	{
		rating.visible = onComboMenu;
		theEXrating.visible = onComboMenu;
		comboNums.visible = onComboMenu;
		dumbTexts.visible = onComboMenu;
		healthBar.visible = onComboMenu;
		scoreTxt.visible = onComboMenu;
		
		timeBar.visible = !onComboMenu;
		timeTxt.visible = !onComboMenu;
		beatText.visible = !onComboMenu;

		controllerPointer.visible = false;
		FlxG.mouse.visible = false;
		if(onComboMenu)
		{
			FlxG.mouse.visible = !controls.controllerMode;
			controllerPointer.visible = controls.controllerMode;
		}

		removeTouchPad();

		var str:String;
		var str2:String;
		final accept:String = (controls.mobileC) ? "A" : (!controls.controllerMode) ? "ACCEPT" : "Start";
		if(onComboMenu)
		{
			str = LanguageBasic.getPhrase('combo_offset', 'Combo Offset');
			addTouchPad('NONE', 'A_B_C');
			addTouchPadCamera();
		} else {
			str = LanguageBasic.getPhrase('note_delay', 'Note/Beat Delay');
			addTouchPad('LEFT_RIGHT', 'A_B_C');
			addTouchPadCamera();
		}

		str2 = LanguageBasic.getPhrase('switch_on_button', '(Press {1} to Switch)', [accept]);

		changeModeText.text = '< ${str.toUpperCase()} ${str2.toUpperCase()} >';
	}

	override function destroy(){
		startMousePos.put();
		startComboOffset.put();
		super.destroy();
	}
}
