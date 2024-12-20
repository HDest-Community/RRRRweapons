class RI_912CFE:HDBulletActor{
	default{
		pushfactor 0.4;
		mass 2330;
		speed 1100;
		accuracy 666;
		stamina 2317;
		woundhealth 80;
		hdbulletactor.hardness 5;
		hdbulletactor.distantsound "world/shotgunfar";
		hdbulletactor.distantsoundvol 3.;
		seesound "weapons/riflecrack";
	}
}
class RI_23:HDBulletActor{  //KS-23
	default{
		pushfactor 0.5;
		mass 80;
		speed 750;
		accuracy 300;
		stamina 900;
		woundhealth 10;
		hdbulletactor.hardness 0;
		hdbulletactor.distantsound "world/shotgunfar";
		hdbulletactor.distantsoundvol .2;
	}
}

class RItest:HDCheatWep{
	default{
		weapon.slotnumber 1;
		hdweapon.refid "rit";
		tag "bullet righter (cheat!)";
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc,string whichdot
	){
		double dotoff=max(abs(bob.x),abs(bob.y));
		if(dotoff<10){
			sb.drawimage(
				"RPRFRNT",(0,0)+bob*1.6,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				alpha:0.8-dotoff*0.04,scale:(0.8,0.8)
			);
		}
		sb.drawimage(
			"revbkst",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
			scale:(1.6,1.6)
		);
		int airburst=hdw.airburst;
		if(airburst)sb.drawnum(airburst,
			10+bob.x,9+bob.y,sb.DI_SCREEN_CENTER,Font.CR_BLACK
		);
	}
	states{
	fire:
/*
	hold:
		TNT1 A 4 A_FireHDGL();
		TNT1 A 0 A_Refire();
		goto ready;
*/
		TNT1 A 0{
			if(player.cmd.buttons&BT_USE)HDBulletActor.FireBullet(self,"HDB_bronto");
			else HDBulletActor.FireBullet(self,"RI_912CFE");
		}goto nope;
	altfire:
		TNT1 A 0{
			HDBulletActor.FireBullet(self,"HDB_776");
		}goto nope;
	reload:
		TNT1 A 0{
			HDBulletActor.FireBullet(self,"HDB_426");
		}goto nope;
	user2:
		TNT1 A 0{
			HDBulletActor.FireBullet(self,"HDB_50");
//			HDBulletActor.FireBullet(self,"HDB_00",spread:6,amount:7);
		}goto nope;
	}
}