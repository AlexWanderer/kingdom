package
{
    import flash.geom.Point;
    
    import org.flixel.FlxSprite;
    import org.flixel.FlxG;
    import org.flixel.FlxObject;
    import org.flixel.FlxPoint;
    import org.flixel.FlxGroup;
    import org.flixel.FlxSound;
    
    public class Citizen extends FlxSprite{
        
        [Embed(source='/assets/gfx/beggar.png')]    public static const BeggarImg:Class;
        [Embed(source='/assets/gfx/citizen.png')]   public static const PoorImg:Class;
        [Embed(source='/assets/gfx/hunter.png')]    public static const HunterImg:Class;
        [Embed(source='/assets/gfx/farmer.png')]    public static const FarmerImg:Class;
        
        [Embed(source="/assets/sound/shoot.mp3")] public static const ShootSound:Class;
        [Embed(source="/assets/sound/powerup.mp3")] public static const PowerupSound:Class;
        [Embed(source="/assets/sound/hitcitizen.mp3")] public static const HitSound:Class;

        public static var shootSound:FlxSound = FlxG.loadSound(ShootSound);
        
        public static const BASE_COLOR:uint = 0xFF567271;
        public static const BASE_SHADE:uint = 0xFF394b4a;
        public static const BASE_SKIN:uint = 0xFFedbebf;
        public static const BASE_DARK:uint = 0xFFbd9898;
        public static const BASE_EYES:uint = 0xFFa18383;
        
        public static const BEGGAR:int = 0;
        public static const POOR:int   = 1;
        public static const FARMER:int = 2;
        public static const HUNTER:int = 3;
        
        // Behaviors
        public static const IDLE:int        = 0;
        public static const SHOOT:int       = 1;
        public static const JUST_SHOT:int   = 2;
        public static const SHOVEL:int      = 3;
		public static const GIVE:int        = 4;
		public static const JUST_HACKED:int = 5;
        public static const COWER:int       = 6;
        
        
        // Behavior times
        public static const SHOOT_COOLDOWN_GUARD:Number = 1.4;
        public static const SHOOT_COOLDOWN:Number = 2.0;
        public static const HACK_COOLDOWN:Number = 4.0;        
        public static const SHOVEL_PERIOD:Number = 4.0;
        public static const SHOVEL_TIME:Number = 1.0;
        public static const SHOVEL_GOAL_DIST:Number = 600;
		public static const GIVE_COOLDOWN:Number = 10.0;
        public static const COWER_COOLDOWN:Number = 5.0;

        // Other consts
        public static const HUNTER_BORDER_RANGE:Number = 256;
        public static const MAX_HUNGRY:Number = 5;
        
        // Variables
        public var occupation:int   = BEGGAR;
        public var action:int       = IDLE;
        public var guarding:Boolean = false;
        public var t:Number         = 0;
        public var goal:Number;
        public var myColor:uint;
        public var skin:uint;
        public var coins:int = 0;
		public var giveCooldown:Number = 0;
        public var shovelCooldown:Number = 0;
		public var target:FlxObject;
        public var guardLeftBorder:Boolean;
        public var hungry:int = 0;
                
        public var playstate:PlayState;
        public var castle:Castle;
        
        public function Citizen(X:int,Y:int){
            super(X,Y);
            goal = FlxG.worldBounds.width/2;
            drag.x = 500;
            guardLeftBorder = (FlxG.random() > 0.5);
            myColor = Utils.HSVtoRGB(FlxG.random()*360, 0.1+FlxG.random()*0.2, 0.6);
            var d:Number = Math.random() * 20;
            skin = Utils.HSVtoRGB(d, 0.19 + (d / 100), 0.97 - (d / 33));

            playstate = FlxG.state as PlayState;
            castle = playstate.castle;
			addAnimationCallback(this.animationFrame);
            morph(BEGGAR);    
        }
        
        public function morph(occ:int):Citizen{
            action = IDLE;
            _animations = new Array();
            if (occ != BEGGAR && coins <= 0){
                coins ++;
            }
            switch(occ){
                case BEGGAR:
                    if (occupation != BEGGAR)
                        playstate.beggars.add(playstate.characters.remove(this,true));
                    loadGraphic(BeggarImg,true,true,32,32,true);
                    addAnimation('walk',[0,1,2,3,4,5],5,true);
                    addAnimation('idle',[7,8,7,8,7,6],2,true);
                    addAnimation('cower',[9,10],2,false);
                    maxVelocity.x = 15;
                    hungry = 0;
                    break;
                case POOR:
                    if (occupation == BEGGAR)
                        playstate.characters.add(playstate.beggars.remove(this,true));
                    loadGraphic(PoorImg,true,true,32,32,true);
                    Utils.replaceColor(pixels, BASE_COLOR, myColor);
                    Utils.replaceColor(pixels, BASE_SHADE, Utils.interpolateColor(myColor,0xFF000000,0.2));
                    maxVelocity.x = 17;
                    addAnimation('walk',[0,1,2,3,4,5],10,true);
                    addAnimation('idle',[0,6,0,6,0,7],2,true);
                    break;
                case HUNTER:
                    if (guardLeftBorder){
                        myColor = Utils.HSVtoRGB(220 + FlxG.random() * 20, 0.2+FlxG.random()*0.3, 0.7);
                    } else {
                        myColor = Utils.HSVtoRGB(0 + FlxG.random() * 20, 0.2+FlxG.random()*0.3, 0.7);
                    }
                    loadGraphic(HunterImg,true,true,32,32,true);
                    Utils.replaceColor(pixels, BASE_COLOR, myColor);
                    Utils.replaceColor(pixels, BASE_SHADE, Utils.interpolateColor(myColor,0xFF000000,0.2));
                    maxVelocity.x = 18;
                    addAnimation('walk',[0,1,2,3,4,5],10,true);
                    addAnimation('idle',[6,7,6,7,6,8],2,true);
                    addAnimation('shoot',[9,10,0],6,false);
					addAnimation('give',[11,12,13],15,false);
                    break;
                case FARMER:
                    loadGraphic(FarmerImg,true,true,32,32,true);
                    Utils.replaceColor(pixels, BASE_COLOR, myColor);
                    Utils.replaceColor(pixels, BASE_SHADE, Utils.interpolateColor(myColor,0xFF000000,0.2));
                    maxVelocity.x = 21 + Math.random() * 3;
                    addAnimation('walk',[0,1,2,3,4,5],12,true);
                    addAnimation('idle',[6,7,6,7,6,8],2,true);
                    addAnimation('shovel',[8,9,10,9],6,true)
					addAnimation('give',[11,12,13],15,false);
					addAnimation('hack',[14],15,false);
                    break;
            }

            Utils.replaceColor(pixels, BASE_SKIN, skin);
            Utils.replaceColor(pixels, BASE_DARK, Utils.interpolateColor(skin,0xFF000000,0.2));
            Utils.replaceColor(pixels, BASE_EYES, Utils.interpolateColor(skin,0xFF000000,0.5));
            drawFrame(true);
            occupation = occ;
            offset.x = 12;
            offset.y = 8;
            width = 8;
            height = 24;
            pickNewGoal();
            return this;
        }
        
        public function pickup(coin:FlxObject):void{
            if (!coin.alive) return;
			var c:Coin = coin as Coin;
			// Return if the coin doesn't belong to me.
			if (c.owner != null && c.owner != this){
				return;
			}
            c.kill();
            // flicker();
            var s:Sparkle = (FlxG.state as PlayState).fx.recycle(Sparkle) as Sparkle;
            s.reset(x-4, y+8);
            if (occupation == BEGGAR) {
                playstate.recruitedCitizen = true;
                morph(POOR);
                FlxG.play(PowerupSound).proximity(x, y, playstate.player, FlxG.width * 0.75)
            }
            coins ++;
        }
		
		public function giveTaxes(p:Player):void{
			if (occupation == HUNTER || occupation == FARMER){
				if (action == IDLE && coins > 3 && giveCooldown <= 0){
					action = GIVE;
                    coins -= 2;
					play('give');
					p.changeCoins(1);
					giveCooldown = GIVE_COOLDOWN;
				}
			}
		}
        
        public function hitByTroll(troll:Troll):void{
            // Farmers can defend.
            if (occupation == FARMER && action != JUST_HACKED){
                action = JUST_HACKED;
                play("hack");
                t = 0;
                troll.getShot();
            } else if (coins > 0 && !troll.hasCoin){
                (playstate.coins.recycle(Coin) as Coin).drop(this, playstate.player);
                FlxG.play(HitSound).proximity(x, y, playstate.player, FlxG.width);
                coins = (coins > 1) ? 1 : 0;
                Utils.explode(this, playstate.gibs);
                if (coins == 0){
                    morph(BEGGAR);
                } else if (coins == 1){
                    morph(POOR);
                }
            }
            if (occupation == BEGGAR && action == IDLE){
                action = COWER;
                play('cower', true);
            }
        }
        
        public function checkShootable(group:FlxGroup):void{
            var c:FlxObject;
            for (var i:int = 0; i < group.length; i++){
                c = group.members[i];
                if (c != null && c.alive && c.exists && Math.abs(c.x - x) < 96){
                    // FlxG.log("Shooting "+c+" at "+c.x+','+c.y);
                    play('shoot', true);
                    shootSound.play(false);
                    shootSound.proximity(x, y, playstate.player, FlxG.width);
					// walk 1 pixel towards goal, just to get
					// the facing right
                    goal = (c.x > x) ? x + 1 : x - 1;
                    facing = (goal > x) ? RIGHT : LEFT;
					target = c;
                    action = SHOOT;
                    t = 0;
                    break;
                }
            }
        }
        
        public function checkWork(group:FlxGroup):void{
            var c:FlxObject;
            for (var i:int = 0; i < group.length; i ++){
                c = group.members[i];
                if (c != null){
                    if (x > c.x && x+width < c.x+c.width){
                        if ((c as Workable).needsWork()){
                            (c as Workable).work(this);
                            play('shovel',true);
                            action = SHOVEL;
                            shovelCooldown = SHOVEL_PERIOD;
                            t = 0;
                        }
                    }
                }
            }
        }
        
        public function checkGuard():void{
            if (action == IDLE && castle.archer_positions.length > 0){
                if (Math.abs(castle.x-x) < 192) {
                    for (var i:int = 0; i < castle.archer_positions.length; i++){
                        var pos:FlxPoint = castle.archer_positions[i];
                        if(Math.abs(castle.x+pos.x-x) < 4){
                            x = castle.x + pos.x;
                            y = castle.y + pos.y;
                            guarding = true;
                            playstate.archers.add(playstate.characters.remove(this,true));
                            castle.archer_positions.splice(i,1);
                            break;
                        }
                    }
                }
            }
        }
        
        public function leaveGuard():void{
            castle.archer_positions.push(new FlxPoint(x,y));
            playstate.characters.add(playstate.archers.remove(this));
            action == IDLE;
            guarding = false;
        }
        
        public function pickNewGoal(preset:Number = NaN):void{
            //TODO !!! Hunters don't target well at night
            var a:Attention = playstate.fx.recycle(Attention) as Attention;
            a.appearAt(this);
            if (!isNaN(preset)){
                goal = preset;
                return
            }
            if (occupation == POOR){
                var shop:Shop = (playstate.shops.getRandom() as Shop);
                goal = shop.x + shop.width/2;
                return;
            }
			if (coins > 4){
				goal = playstate.player.x;
				return;
			}
            if (occupation == FARMER) {
                // Otherwise check for a wall to work on
                var needWork:Array = new Array();
                var dist:Number = Number.MAX_VALUE;
                var wall:Wall, closestWall:Wall = null;
                for (var i:int = 0; i < playstate.walls.length; i++){
                    wall = playstate.walls.members[i] as Wall;
                    if (wall != null && wall.needsWork() && (Math.abs(wall.x - x) < dist)){
                        closestWall = wall;
                        dist = Math.abs(wall.x - x);
                    }                    
                }
                if (closestWall != null){
                    goal = closestWall.x + closestWall.width / 2;
                    return;    
                }
                
            }
            
            var l:int, r:int;
            
            if (occupation == HUNTER) {
                // Hunters gather around borders at night
                if (playstate.weather.timeOfDay >= 0.65 || playstate.weather.timeOfDay < 0.20){
                    if (guardLeftBorder){
                        l = playstate.kingdomLeft;
                        r = playstate.kingdomLeft + 32;
                    } else {
                        l = playstate.kingdomRight - 32;
                        r = playstate.kingdomRight;
                    }
                } else {
                    l = playstate.kingdomLeft - HUNTER_BORDER_RANGE;
                    r = playstate.kingdomRight + HUNTER_BORDER_RANGE;
                }
            } else if (occupation == BEGGAR){
                // Beggars gather outside borders
                if (playstate.beggars.countLiving() > playstate.minBeggars){
                    hungry ++;
                    if (hungry > MAX_HUNGRY){
                        Utils.explode(this, playstate.gibs, 1.0);
                        kill();
                    }
                }
                if (x < PlayState.GAME_WIDTH/2){
                    l = playstate.kingdomLeft - 256;
                    r = playstate.kingdomLeft;
                } else {
                    l = playstate.kingdomRight;
                    r = playstate.kingdomRight + 256;
                }
            } else {
                // Move anywhere within the kingdom
                l = playstate.kingdomLeft;
                r = playstate.kingdomRight;
            }
            goal = int(FlxG.random()*(r-l) + l);
            /*FlxG.log("Citizen (" + occupation + ") picked goal " + goal)*/
        }
        
		
		public function animationFrame(animName:String, frameNum:uint, frameIndex:uint):void{
			if (animName == 'give' && frameNum == 2){
				action = IDLE;
				play('idle');
			}

            if (animName == 'shovel'){
                var d:Dust = playstate.fx.recycle(Dust) as Dust;
                d.reset(x + ((facing == RIGHT) ? 14 : -6), y + 19);
            }
		}

        
        override public function update():void {
            acceleration.x = 0;
            t += FlxG.elapsed;
            shovelCooldown -= FlxG.elapsed;
			giveCooldown -= FlxG.elapsed;

            // IDLE MOVING AROUND
            
            if(guarding && occupation == HUNTER){
                play('idle');
                facing = (goal > x) ? RIGHT : LEFT;
            } else if (action == IDLE){
                facing = (goal > x) ? RIGHT : LEFT;
                // Near Goal
                if (Math.abs(goal - x) < 2){
                    if (t > 2.0 && FlxG.random() < 0.3) {
                        t = 0;
                        pickNewGoal();
                    } else {
                        play('idle');
                    }
                // Far away from goal
                } else {
                    play('walk');
                    acceleration.x = (facing == RIGHT) ? maxVelocity.x*10 : -maxVelocity.x*10;
                    y = playstate.groundHeight - height;
                    
                }                
            }
            
            // Specific Behavior
            if (occupation == HUNTER){
                // Shooting cycle
                if (action == SHOOT && t > 0.16){
                    (playstate.arrows.recycle(Arrow) as Arrow).shotFrom(this, target);
                    t = 0;
                    action = JUST_SHOT;
                } else if (action == JUST_SHOT && t > (guarding ? SHOOT_COOLDOWN_GUARD : SHOOT_COOLDOWN)){
                    t = 0;
                    action = IDLE;
                } else if (action == IDLE){
                    checkShootable(playstate.trolls);
                    checkShootable(playstate.trollsNoCollide);
                    // Check for idle again since we could be shooting a Troll.
                    if (action == IDLE){
                        checkShootable(playstate.bunnies);
                    }                    
                }
                // Check if we need to take up a guard post.
                checkGuard();
            } else if (occupation == FARMER){
                if (action == JUST_HACKED && t > HACK_COOLDOWN ){
                    t = 0;
                    action = IDLE;
                }
                if (shovelCooldown <= 0 && action == IDLE) {
                    checkWork(playstate.walls);
                    checkWork(playstate.farmlands);
                } else if (action == SHOVEL && t > SHOVEL_TIME){
                    t = 0;
                    action = IDLE;
                }
            } else if (occupation == BEGGAR){
                if (action == COWER && t > COWER_COOLDOWN){
                    t = 0;
                    action = IDLE;
                }
            }
            
            
            super.update();
        }
        
        
    }
}
