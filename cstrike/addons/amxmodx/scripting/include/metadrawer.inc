/* MetaDrawer Include
*
*  Version: 1.2.5
*  Author: Agung.
*  Thanks to: Nagi, Martin, Csoldjb.
*
\* =============================== */

#if defined _metadrawer_included
 #endinput
#endif
#define _metadrawer_included

#if AMXX_VERSION_NUM >= 175
 #pragma reqlib metadrawer
 #if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib metadrawer
 #endif
#else
 #pragma library metadrawer
#endif

/* Draw Alignment */
#define ALIGN_NORMAL	0	
#define ALIGN_RIGHT	1
#define ALIGN_BOTTOM	2

/* Font Style */
enum eFontStyle
{
	FS_NONE	= 0,
	FS_ITALIC = 0x001,
	FS_UNDERLINE = 0x002,
	FS_STRIKEOUT = 0x004,
	FS_SYMBOL = 0x008,
	FS_ANTIALIAS = 0x010,
	FS_GAUSSIANBLUR = 0x020,
	FS_ROTARY = 0x040,
	FS_DROPSHADOW = 0x080,
	FS_ADDITIVE = 0x100,
	FS_OUTLINE = 0x200
};

/* Font Weight */
enum eFontWeight
{
	FW_DONTCARE = 0,
	FW_THIN = 100,
	FW_EXTRALIGHT = 200,
	FW_LIGHT = 300,
	FW_NORMAL = 400,
	FW_MEDIUM = 500,
	FW_SEMIBOLD = 600,
	FW_BOLD = 700,
	FW_EXTRABOLD = 800,
	FW_HEAVY = 900
};

/* Sprite Type */
enum eSpriteType
{
	SPR_NORMAL = 0,
	SPR_HOLES = 1,
	SPR_ADDITIVE = 2
};

/* # Function: Get screen width size. */
native md_getscreenwidth()

/* # Function: Get screen height size. */
native md_getscreenheight()

/* # Function: Get video renderer mode.
 * result: 
 *	0 = software mode.
 *	1 = opengl mode.
 *	2 = d3d mode. */
native md_getvideorenderer()

/* # Function: Add font resource from spesific directory (.ttf file).
 * # Param(s): (1)
 * fontFileName : font file [example: "gfx/font.ttf"]. */
native md_loadfontfile(const fontFileName[])

/* # Function:  Bind a font from windows fonts directory and from resource (md_loadfontfile) to (md_drawtext).
 * # Param(s): (5)
 * channel	: font channel [0 ~ 256].
 * fontName	: font name.
 * size		: font size.
 * fontStyle	: font style [eFontStyle].
 * fontWeight	: font weight [eFontWeight]. */
native md_initfont(channel, const fontName[] = "Verdana", size = 14, eFontStyle:fontStyle = FS_ANTIALIAS, eFontWeight:fontWeight = FW_NORMAL)

/* # Function: Draw text.
 * # Param(s): (15)
 * id		: target player ID.
 * channel	: text channel [0 ~ 256].
 * text		: text to display.
 * x		: x coord [0.0 ~ 1.0].
 * y		: y coord [0.0 ~ 1.0].
 * centerX	: put x coord on center of text width [1 = Yes, 0 = No].
 * centerY	: put y coord on center of text height [1 = Yes, 0 = No].
 * r		: red [0 ~ 255].
 * g		: green [0 ~ 255].
 * b		: blue [0 ~ 255].
 * a		: transparent [0 ~ 255].
 * fadeInTime	: duration of fade in.
 * FadeOutTime	: duration of fade out.
 * holdTime	: hold time [0.0 = always draw].
 * align	: alignment [ALIGN_NORMAL = none, ALIGN_RIGHT = x coord count from right, ALIGN_BOTTOM = y coord count from bottom, ALIGN_RIGHT|ALIGN_BOTTOM = two combined]. */
native md_drawtext(id, channel, const text[], Float:x, Float:y, centerX, centerY, r, g, b, a, Float:fadeInTime, Float:FadeOutTime, Float:holdTime, align = ALIGN_NORMAL)

/* # Function: Load image file (TGA / PNG).
 * # Param(s): (1)
 * imageFile	: full path of the image file, extension is required [example: "gfx/hud.png"]. */
native md_loadimage(const imageFile[])

/* # Function: Draw image (TGA / PNG).
 * # Param(s): (18)
 * id		: target player ID.
 * channel	: image channel [0 ~ 512].
 * isDefined	: image defined in (gfx/hud.txt) [1 = Yes, 0 = No].
 * imageName	: image name.
 * x		: x coord [0.0 ~ 1.0].
 * y		: y coord [0.0 ~ 1.0].
 * centerX	: put x coord on center of image width [1 = Yes, 0 = No].
 * centerY	: put y coord on center of image height [1 = Yes, 0 = No].
 * r		: red [0 ~ 255].
 * g		: green [0 ~ 255].
 * b		: blue [0 ~ 255].
 * a		: transparent [0 ~ 255].
 * fadeInTime	: duration of fade in.
 * FadeOutTime	: duration of fade out.
 * holdTime	: hold time [0.0 = always draw].
 * align	: alignment [ALIGN_NORMAL = none, ALIGN_RIGHT = x coord count from right, ALIGN_BOTTOM = y coord count from bottom, ALIGN_RIGHT|ALIGN_BOTTOM = two combined].
 * customWidth	: custom width [0 = return to original width].
 * customHeight	: custom height [0 = return to original height]. */
native md_drawimage(id, channel, isDefined, const imageName[], Float:x, Float:y, centerX, centerY, r, g, b, a, Float:fadeInTime, Float:FadeOutTime, Float:holdTime, align = ALIGN_NORMAL, customWidth = 0, customHeight = 0)

/* # Function: Load sprite file (SPR).
 * # Param(s): (1)
 * spriteFile	: full path of the sprite file. extension is required. [example: "sprites/hud.spr"].*/
native md_loadsprite(const spriteFile[])

/* # Function: Draw Sprite.
 * # Param(s): (19)
 * id		: target player ID.
 * channel	: sprite channel [0 ~ 256].
 * isDefined	: sprite defined in (sprites/hud.txt) [1 = Yes, 0 = No].
 * spriteName	: sprite name.
 * x		: x coord [0.0 ~ 1.0].
 * y		: y coord [0.0 ~ 1.0].
 * centerX	: put x coord on center of sprite width [1 = Yes, 0 = No].
 * centerY	: put y coord on center of sprite height [1 = Yes, 0 = No].
 * r		: red [0 ~ 255].
 * g		: green [0 ~ 255].
 * b		: blue [0 ~ 255].
 * a		: transparent [0 ~ 255].
 * fadeInTime	: duration of fade in.
 * FadeOutTime	: duration of fade out.
 * holdTime	: hold time [0.0 = always draw].
 * spriteType	: sprite image type [SPR_NORMAL/SPR_HOLES/SPR_ADDITIVE].
 * align	: alignment [ALIGN_NORMAL = none, ALIGN_RIGHT = x coord count from right, ALIGN_BOTTOM = y coord count from bottom, ALIGN_RIGHT|ALIGN_BOTTOM = two combined].
 * customWidth	: custom width [0 = return to original width].
 * customHeight	: custom height [0 = return to original height]. */
native md_drawsprite(id, channel, isDefined, const spriteName[], Float:x, Float:y, centerX, centerY, r, g, b, a, Float:fadeInTime, Float:FadeOutTime, Float:holdTime, eSpriteType:spriteType, align = ALIGN_NORMAL, customWidth = 0, customHeight = 0)

/* # Function: Play sprite animation.
 * # Param(s): (17)
 * id		: target player ID.
 * channel	: sprite channel (0 ~ 256).
 * spriteFile	: full path of the sprite file. extension is required.
 * x		: x coord [0.0 ~ 1.0].
 * y		: y coord [0.0 ~ 1.0].
 * centerX	: put x coord on center of sprite width [1 = Yes, 0 = No].
 * centerY	: put y coord on center of sprite height [1 = Yes, 0 = No].
 * r		: red [0 ~ 255].
 * g		: green [0 ~ 255].
 * b		: blue [0 ~ 255].
 * a		: transparent [0 ~ 255].
 * frameRate	: frame rate [0 = default frame rate].
 * isLooping	: play looping [1 = Yes, 0 = No].
 * spriteType	: sprite image type [SPR_NORMAL/SPR_HOLES/SPR_ADDITIVE].
 * align	: alignment [ALIGN_NORMAL = none, ALIGN_RIGHT = x coord count from right, ALIGN_BOTTOM = y coord count from bottom, ALIGN_RIGHT|ALIGN_BOTTOM = two combined].
 * customWidth	: custom width [0 = return to original width].
 * customHeight	: custom height [0 = return to original height]. */
native md_playsprite(id, channel, const spriteFile[], Float:x, Float:y, centerX, centerY, r, g, b, a, eSpriteType:spriteType, frameRate = 0, isLooping = 0, align = ALIGN_NORMAL, customWidth = 0, customHeight = 0)

/* # Function: Load bink video.
 * # Param(s): (1)
 * binkName	: full path of the bink file. extension is required [example: "gfx/effects.bik"]. */
native md_loadbink(const binkName[])

/* # Function: Draw bink video.
 * # Param(s): (16)
 * id		: target player ID.
 * channel	: bink channel [0 ~ 64].
 * binkName	: full path of the bink file. extension is required.
 * x		: x coord [0.0 ~ 1.0].
 * y		: y coord [0.0 ~ 1.0].
 * centerX	: put x coord on center of bink width [1 = Yes, 0 = No].
 * centerY	: put y coord on center of bink height [1 = Yes, 0 = No].
 * r		: red [0 ~ 255].
 * g		: green [0 ~ 255].
 * b		: blue [0 ~ 255].
 * a		: transparent [0 ~ 255].
 * frameRate	: frame rate [0 = default frame rate].
 * isLooping	: play looping [1 = Yes, 0 = No].
 * align	: alignment [ALIGN_NORMAL = none, ALIGN_RIGHT = x coord count from right, ALIGN_BOTTOM = y coord count from bottom, ALIGN_RIGHT|ALIGN_BOTTOM = two combined].
 * customWidth	: custom width [0 = return to original width].
 * customHeight	: custom height [0 = return to original height]. */
native md_playbink(id, channel, const binkName[], Float:x, Float:y, centerX, centerY, r, g, b, a, frameRate = 0, isLooping = 0, align = ALIGN_NORMAL, customWidth = 0, customHeight = 0)

/* # Function: Draw rectangle.
 * # Param(s): (16)
 * id		: target player ID.
 * channel	: rectangle channel [0 ~ 64].
 * width	: rectangle width.
 * height	: rectangle height.
 * x		: x coord [0.0 ~ 1.0].
 * y		: y coord [0.0 ~ 1.0].
 * centerX	: put x coord on center of rectangle width [1 = Yes, 0 = No].
 * centerY	: put y coord on center of rectangle height [1 = Yes, 0 = No].
 * r		: red [0 ~ 255].
 * g		: green [0 ~ 255].
 * b		: blue [0 ~ 255].
 * a		: transparent [0 ~ 255].
 * fadeInTime	: duration of fade in.
 * FadeOutTime	: duration of fade out.
 * holdTime	: hold time [0.0 = always draw].
 * align	: alignment [ALIGN_NORMAL = none, ALIGN_RIGHT = x coord count from right, ALIGN_BOTTOM = y coord count from bottom, ALIGN_RIGHT|ALIGN_BOTTOM = two combined]. */
native md_drawrectangle(id, channel, width, height, Float:x, Float:y, centerX, centerY, r, g, b, a, Float:fadeInTime, Float:FadeOutTime, Float:holdTime, align = ALIGN_NORMAL)

/* # Function: Draw radar overview.
 * # Param(s): (20)
 * id		: target player ID.
 * isEnable	: enable radar [1 = Yes, 0 = No].
 * width	: radar width [max: 400].
 * height	: radar height [max: 400].
 * x		: x coord [0.0 ~ 1.0].
 * y		: y coord [0.0 ~ 1.0].
 * r		: red [0 ~ 255].
 * g		: green [0 ~ 255].
 * b		: blue [0 ~ 255].
 * a		: transparent [0 ~ 255].
 * align	: alignment [ALIGN_NORMAL = none, ALIGN_RIGHT = x coord count from right, ALIGN_BOTTOM = y coord count from bottom, ALIGN_RIGHT|ALIGN_BOTTOM = two combined].
 * isCircle	: enable circular radar [1 = Yes, 0 = No] (Note: Only work in OpenGL renderer).
 * enableBorder	: enable radar border [1 = Yes, 0 = No].
 * showLocation	: show text player location [1 = Yes, 0 = No].
 * locationY	: distance between radar and text location.
 * tr		: text red [0 ~ 255].
 * tg		: text green [0 ~ 255].
 * tb		: text blue [0 ~ 255].
 * ta		: text transparent [0 ~ 255]. 
 * fontChannel	: bind a font with md_initfont [0 = using default font]. */
native md_drawradar(id, isEnable, width, height, Float:x, Float:y, r, g, b, a, align, isCircle, enableBorder, showLocation = 1, locationY = 10, tr = 0, tg = 204, tb = 0, ta = 255, fontChannel = 0)

/* # Function: Draw sprite icon on radar.
 * # Param(s): (10)
 * id		: target player ID.
 * channel	: sprite icon channel [0 ~ 64].
 * isDefined	: sprite defined in (sprites/hud.txt) [1 = Yes, 0 = No].
 * spriteName	: sprite name.
 * origin[3] 	: entity origin coord [origin[0] -> x, origin[1] -> y, origin[2] -> z].
 * r		: red [0 ~ 255].
 * g		: green [0 ~ 255].
 * b		: blue [0 ~ 255].
 * a		: transparent [0 ~ 255].
 * spriteType	: sprite image type [SPR_NORMAL/SPR_HOLES/SPR_ADDITIVE]. */
native md_drawspriteonradar(id, channel, isDefined, const spriteName[], origin[3], r, g, b, a, eSpriteType:spriteType)

/* # Function: Draw sprite icon to indicate the position of an entity.
 * # Param(s): (17)
 * id		: target player ID.
 * channel	: sprite icon channel [0 ~ 64].
 * isDefined	: sprite defined in (sprites/hud.txt) [1 = Yes, 0 = No].
 * spriteName	: sprite name.
 * origin[3] 	: entity origin coord [origin[0] -> x, origin[1] -> y, origin[2] -> z].
 * r		: red [0 ~ 255].
 * g		: green [0 ~ 255].
 * b		: blue [0 ~ 255].
 * a		: transparent [0 ~ 255].
 * spriteType	: sprite image type [SPR_NORMAL/SPR_HOLES/SPR_ADDITIVE].
 * displayDistance	: display text distance between player and entity (Unit: meter) [1 = Yes, 0 = No].
 * tr		: text red [0 ~ 255].
 * tg		: text green [0 ~ 255].
 * tb		: text blue [0 ~ 255].
 * ta		: text transparent [0 ~ 255].
 * customWidth	: custom width [0 = return to original width].
 * customHeight	: custom height [0 = return to original height]. */
native md_drawentitysprite(id, channel, isDefined, const spriteName[], origin[3], r, g, b, a, eSpriteType:spriteType, displayDistance, tr, tg, tb, ta, customWidth = 0, customHeight = 0)

/* # Function: Show teammate's name on player head.
 * # Param(s): (6)
 * id		: target player ID.
 * isEnable	: enable teammate's name [1 = Yes, 0 = No].
 * r		: red [0 ~ 255].
 * g		: green [0 ~ 255].
 * b		: blue [0 ~ 255].
 * a		: transparent [0 ~ 255]. */
native md_showteammatename(id, isEnable, r, g, b, a)

/* # Function: Show extra ammo hud.
 * # Param(s): (2)
 * id		: target player ID.
 * isEnable	: enable extra ammo [1 = Yes, 0 = No]. 
 * ammo		: number of extra ammo. */
native md_showextraammo(id, isEnable, ammo)

/* # Function: Set view entity body.
 * # Param(s): (2)
 * id		: target player ID.
 * body		: body index of model. */
native md_setviewentitybody(id, body = -1)

/* # Function: Remove drawing.
 * # Param(s): (3)
 * id		: target player ID.
 * whichNative	= drawing native.
 *	0 = md_drawtext.
 *	1 = md_drawimage.
 *	2 = md_drawsprite/md_playsprite.
 *	3 = md_playbink.
 *	4 = md_drawrectangle.
 *	5 = md_drawspriteonradar.
 *	6 = md_drawentitysprite.
 * channel	: drawing channel. */
native md_removedrawing(id, whichNative, channel)