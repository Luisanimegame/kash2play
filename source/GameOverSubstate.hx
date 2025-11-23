package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Boyfriend;
	var camFollow:FlxObject;
	
	// bro, again!?!
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;
	
	public static var characterName:String = 'boyfriend-dead';
	public static var instance:GameOverSubstate;

	var stageSuffix:String = "";
	
	override function create()
	{
		instance = this;
		
		super.create();
	}

	public function new(x:Float, y:Float)
	{
		super();

		Conductor.songPosition = 0;

		boyfriend = new Boyfriend(x, y, characterName);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);
		
		camFollow = new FlxObject(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y, 1, 1);
		
		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
		Conductor.changeBPM(100);
		
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');
		
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);
	}

	var isFollowingAlready:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		#if mobile
        var jusTouched:Bool = false;

        for (touch in FlxG.touches.list)
          if (touch.justPressed)
            jusTouched = true;
        #end
        
        if(updateCamera) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT #if mobile || jusTouched #end)
		{
			endBullshit();
		}

		if (controls.BACK #if android || FlxG.android.justReleased.BACK #end)
		{
			FlxG.sound.music.stop();

			if (PlayState.isStoryMode)
				FlxG.switchState(new StoryMenuState());
			else
				FlxG.switchState(new FreeplayState());
			PlayState.loadRep = false;
		}

		if (boyfriend.animation.curAnim.name == 'firstDeath' && boyfriend.animation.curAnim.curFrame == 12)
		{
			FlxG.camera.follow(camFollowPos, LOCKON, 1);
			updateCamera = true;
			isFollowingAlready = true;
		}

		if (boyfriend.animation.curAnim.name == 'firstDeath' && boyfriend.animation.curAnim.finished)
		{
			FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix));
			boyfriend.startedDeath = true;
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	override function beatHit()
	{
		super.beatHit();

		FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					LoadingState.loadAndSwitchState(new PlayState());
				});
			});
		}
	}
}
