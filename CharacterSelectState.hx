package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import objects.Character;
import objects.HealthIcon;

#if mobile
import mobile.backend.utils.TouchUtil;
#end

typedef SelectableChar =
{
	var id:String; // nombre del JSON en characters/ (sin .json)
	var name:String; // nombre que se muestra en pantalla
}

class CharacterSelectState extends MusicBeatState
{
	// Personaje elegido. PlayState lo lee. null = usar el de la canción.
	public static var selectedCharacter:String = null;
	public static var curSelected:Int = 0;

	// >>> EDITA ESTA LISTA CON TUS PERSONAJES <<<
	public static var characters:Array<SelectableChar> = [
		{id: 'bf', name: 'Boyfriend'},
		{id: 'bf-christmas', name: 'Boyfriend Navidad'},
		{id: 'bf-car', name: 'Boyfriend Auto'}
	];

	var bg:FlxSprite;
	var preview:Character;
	var icon:HealthIcon;
	var nameText:FlxText;
	var counterText:FlxText;
	var hintText:FlxText;

	var selected:Bool = false;
	var danceTime:Float = 0;

	override function create()
	{
		persistentUpdate = persistentDraw = true;

		if (curSelected >= characters.length || curSelected < 0)
			curSelected = 0;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		var title:FlxText = new FlxText(0, 20, FlxG.width, 'ELIGE TU PERSONAJE', 32);
		title.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		title.scrollFactor.set();
		add(title);

		nameText = new FlxText(0, FlxG.height - 150, FlxG.width, '', 40);
		nameText.setFormat(Paths.font('vcr.ttf'), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nameText.scrollFactor.set();
		add(nameText);

		counterText = new FlxText(0, FlxG.height - 105, FlxG.width, '', 22);
		counterText.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		counterText.scrollFactor.set();
		add(counterText);

		hintText = new FlxText(0, 70, FlxG.width, #if mobile 'Desliza o usa las flechas' #else 'Izquierda / Derecha' #end, 18);
		hintText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		hintText.scrollFactor.set();
		add(hintText);

		icon = new HealthIcon('bf', true);
		icon.scrollFactor.set();
		add(icon);

		changeSelection(0, false);

		#if mobile
		addVirtualPad('LEFT_RIGHT', 'A_B');
		#end

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (!selected)
		{
			if (controls.UI_LEFT_P)
				changeSelection(-1);
			if (controls.UI_RIGHT_P)
				changeSelection(1);

			#if mobile
			if (TouchUtil.justSwiped)
			{
				if (TouchUtil.swipeLeft)
					changeSelection(1);
				else if (TouchUtil.swipeRight)
					changeSelection(-1);
			}
			#end

			if (controls.BACK)
			{
				selected = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new FreeplayState());
			}
			else if (controls.ACCEPT)
			{
				selected = true;
				selectedCharacter = characters[curSelected].id;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				if (preview != null && preview.animOffsets.exists('hey'))
					preview.playAnim('hey', true);

				new FlxTimer().start(0.9, function(tmr:FlxTimer)
				{
					// PlayState.SONG ya fue cargado por FreeplayState
					LoadingState.loadAndSwitchState(new PlayState());
				});
			}
		}

		// El personaje hace su idle aunque no suene música
		if (preview != null && !selected)
		{
			danceTime += elapsed;
			if (danceTime >= 0.7)
			{
				danceTime = 0;
				preview.dance();
			}
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		curSelected += change;
		if (curSelected >= characters.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = characters.length - 1;

		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		loadPreview();

		nameText.text = characters[curSelected].name;
		counterText.text = (curSelected + 1) + ' / ' + characters.length;

		icon.changeIcon(preview.healthIcon);
		icon.screenCenter(X);
		icon.y = nameText.y - icon.height - 5;

		var c:Array<Int> = preview.healthColorArray;
		FlxTween.cancelTweensOf(bg);
		FlxTween.color(bg, 0.3, bg.color, FlxColor.fromRGB(c[0], c[1], c[2]), {ease: FlxEase.quadOut});
	}

	function loadPreview()
	{
		if (preview != null)
		{
			remove(preview, true);
			preview.destroy();
		}

		// true = igual que en PlayState (jugador)
		preview = new Character(0, 0, characters[curSelected].id, true);
		preview.scrollFactor.set();

		// Reducir si el personaje es muy grande para el espacio disponible
		var maxH:Float = FlxG.height * 0.45;
		if (preview.frameHeight > maxH)
		{
			var s:Float = maxH / preview.frameHeight;
			preview.scale.set(s, s);
			preview.updateHitbox();
		}

		preview.screenCenter();
		preview.y -= 40;
		preview.dance();
		danceTime = 0;
		add(preview);
	}
}
