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

	// Dónde pisa el personaje sobre el escenario (centro X, base Y)
	static inline var CHAR_X:Float = 640;
	static inline var CHAR_FEET_Y:Float = 520;
	static inline var CHAR_MAX_H:Float = 330;

	var bg:FlxSprite;
	var preview:Character;
	var icon:HealthIcon;
	var nameText:FlxText;
	var counterText:FlxText;
	var hintText:FlxText;
	var arrowLeft:FlxText;
	var arrowRight:FlxText;

	var selected:Bool = false;
	var danceTime:Float = 0;

	// Crea una imagen de la carpeta images/charSelect/ ajustada al ancho/alto de la pantalla
	function addImage(file:String, ?fitWidth:Bool = true, y:Float = 0, alpha:Float = 1):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('charSelect/' + file));
		spr.antialiasing = ClientPrefs.data.antialiasing;
		if (fitWidth)
			spr.setGraphicSize(FlxG.width, 0);
		else
			spr.setGraphicSize(0, FlxG.height);
		spr.updateHitbox();
		spr.screenCenter(X);
		spr.y = y;
		spr.alpha = alpha;
		spr.scrollFactor.set();
		add(spr);
		return spr;
	}

	override function create()
	{
		persistentUpdate = persistentDraw = true;

		if (curSelected >= characters.length || curSelected < 0)
			curSelected = 0;

		// ---- Fondo y escenario (de atrás hacia adelante) ----
		bg = addImage('bg', false, 0);
		addImage('crowd', true, 175);
		addImage('stage', true, 368);

		// Luz detrás del personaje
		var light:FlxSprite = new FlxSprite().loadGraphic(Paths.image('charSelect/light'));
		light.antialiasing = ClientPrefs.data.antialiasing;
		light.setGraphicSize(520, 0);
		light.updateHitbox();
		light.x = CHAR_X - light.width / 2;
		light.y = 250;
		light.alpha = 0.7;
		light.scrollFactor.set();
		add(light);

		// El personaje se crea y se agrega aquí, entre el escenario y el frente
		changeSelection(0, false);

		addImage('blur', true, 264, 0.6);
		addImage('curtains', true, 0);

		// ---- Textos e icono (siempre encima de todo) ----
		nameText = new FlxText(0, 28, FlxG.width, '', 44);
		nameText.setFormat(Paths.font('vcr.ttf'), 44, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nameText.borderSize = 3;
		nameText.scrollFactor.set();
		add(nameText);

		counterText = new FlxText(0, 82, FlxG.width, '', 22);
		counterText.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		counterText.scrollFactor.set();
		add(counterText);

		hintText = new FlxText(0, FlxG.height - 34, FlxG.width, #if mobile 'Toca las flechas o desliza' #else 'Izquierda / Derecha' #end, 18);
		hintText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		hintText.scrollFactor.set();
		add(hintText);

		icon = new HealthIcon('bf', true);
		icon.scrollFactor.set();
		add(icon);

		// Flechas provisionales (cámbialas por tus dibujos cuando los tengas)
		arrowLeft = new FlxText(30, 300, 120, '<', 120);
		arrowLeft.setFormat(Paths.font('vcr.ttf'), 120, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		arrowLeft.borderSize = 4;
		arrowLeft.scrollFactor.set();
		add(arrowLeft);

		arrowRight = new FlxText(FlxG.width - 150, 300, 120, '>', 120);
		arrowRight.setFormat(Paths.font('vcr.ttf'), 120, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		arrowRight.borderSize = 4;
		arrowRight.scrollFactor.set();
		add(arrowRight);

		updateTexts();

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
			else if (TouchUtil.justPressed)
			{
				// Tocar las flechas de los lados
				var tx:Float = TouchUtil.firstTouch.screenX;
				var ty:Float = TouchUtil.firstTouch.screenY;
				if (ty > 220 && ty < 480)
				{
					if (tx < 190)
						changeSelection(-1);
					else if (tx > FlxG.width - 190)
						changeSelection(1);
				}
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
				hintText.text = '¡Seleccionado!';

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

		// Los textos aún no existen la primera vez (se llama desde create)
		if (nameText != null)
			updateTexts();

		var c:Array<Int> = preview.healthColorArray;
		FlxTween.cancelTweensOf(bg);
		FlxTween.color(bg, 0.3, bg.color, FlxColor.fromRGB(c[0], c[1], c[2]), {ease: FlxEase.quadOut});
	}

	function updateTexts()
	{
		nameText.text = characters[curSelected].name;
		counterText.text = (curSelected + 1) + ' / ' + characters.length;

		icon.changeIcon(preview.healthIcon);
		icon.screenCenter(X);
		icon.y = FlxG.height - icon.height - 40;
	}

	function loadPreview()
	{
		var index:Int = -1;
		if (preview != null)
		{
			index = members.indexOf(preview);
			remove(preview, true);
			preview.destroy();
		}

		// true = igual que en PlayState (jugador)
		preview = new Character(0, 0, characters[curSelected].id, true);
		preview.scrollFactor.set();

		// Reducir si el personaje es muy grande
		if (preview.frameHeight > CHAR_MAX_H)
		{
			var s:Float = CHAR_MAX_H / preview.frameHeight;
			preview.scale.set(s, s);
			preview.updateHitbox();
		}

		// Pies sobre el escenario, centrado
		preview.x = CHAR_X - preview.width / 2;
		preview.y = CHAR_FEET_Y - preview.height;
		preview.dance();
		danceTime = 0;

		// Mantener la capa (entre el escenario y el frente) al cambiar de personaje
		if (index >= 0)
			insert(index, preview);
		else
			add(preview);
	}
}
