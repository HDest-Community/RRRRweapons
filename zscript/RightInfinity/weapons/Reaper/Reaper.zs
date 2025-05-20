// ------------------------------------------------------------
// Reaper Assault Shotgun
// ------------------------------------------------------------
const RILD_REAP = "RPR";
const RILD_RPRZMCOOKOFF = 21;

class RIReaper : HDWeapon {

	double shotpower;

	default {
		//$Category "Weapons/Hideous Destructor"
		//$Title "REAPR"
		//$Sprite "ASHTA0"

		weapon.selectionorder 351;
		weapon.slotnumber 3;
		weapon.kickback 30;
		weapon.bobrangex 0.3;
		weapon.bobrangey 0.8;
		weapon.bobspeed 2.5;
		hdweapon.barrelsize 29, 1, 3;

		inventory.icon "ASHTA0";
		scale 0.50;

		tag "$TAG_REAPER";
		inventory.pickupmessage "$PICKUP_REAPER";
		obituary "$OB_REAPER";

		hdweapon.refid RILD_REAP;
		hdweapon.loadoutcodes "
			\cumag - 0/1, drum/box mag
			\cufiremode - 0-2, semi/burst/auto
			\cuchoke - 0-7, 0 skeet, 7 full
			\cusight - alternate sights
			\cugl - underbarrel grenade launcher
			\cuzm - underbarrel carbine";
	}

	override void tick() {
		super.tick();

		if (weaponstatus[ASHTS_UNDERBARREL] == 2) drainheat(ASHTS_HEAT, 12);
	}

	override bool AddSpareWeapon(actor newowner) {return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner, bool reverse, bool doselect) {return GetSpareWeaponRegular(newowner, reverse, doselect);}

	override double gunmass() {
		let mass = 8 + weaponstatus[ASHTS_MAG] * 0.2;

		let underbarrel = weaponstatus[ASHTS_UNDERBARREL];
		switch (weaponstatus[ASHTS_UNDERBARREL]) {
			case 1: mass += 1 + (weaponstatus[0]&ASHTF_GZCHAMBER ? 1 : 0); break; // GL
			case 2: mass += 1 + (weaponstatus[ASHTS_ZMAG] * 0.02);         break; // ZM
			default:                                                       break; // None
		}

		return mass;
	}

	override double weaponbulk() {
		double bulk = 130;
		int mgg = weaponstatus[ASHTS_MAG];
		int magBulk = weaponstatus[ASHTS_BOXER] ? ENC_AST_STK_LOADED : ENC_AST_DRM_LOADED;

		// Calculate Mag Bulk
		bulk += mgg > -1
			? magBulk + mgg * ENC_SHELLLOADED
			: 0;

		// Calculate Underbarrel Bulk
		let underbarrel = weaponstatus[ASHTS_UNDERBARREL];
		if (underbarrel == 1) {

			// GL
			bulk += 25 + (weaponstatus[0]&ASHTF_GZCHAMBER
				? ENC_ROCKETLOADED
				: 0);
		} else if (underbarrel == 2) {

			// ZM
			let mgz = weaponstatus[ASHTS_ZMAG];
			bulk += 90 + (mgz > -1
				? ENC_426MAG_LOADED + (mgz * ENC_426_LOADED)
				: 0);
		}

		return bulk;
	}

	override void loadoutconfigure(string input) {
		int firemode=getloadoutvar(input,"firemode", 1);
		if (firemode>=0)weaponstatus[ASHTS_AUTO]=clamp(firemode, 0, 2);
		int choke=min(getloadoutvar(input,"choke", 1), 7);
		if (choke>=0)weaponstatus[ASHTS_CHOKE]=choke;
		int sight=min(getloadoutvar(input,"sight", 0), 1);
		if (sight>=0)weaponstatus[ASHTS_SIGHTS]=sight;
		int mag=min(getloadoutvar(input,"mag", 1), 1);
		if (mag>=0)weaponstatus[ASHTS_BOXER]=mag;

		if (getloadoutvar(input,"gl", 1)>0)weaponstatus[ASHTS_UNDERBARREL]=1;
		else if (getloadoutvar(input,"zm", 1)>0)weaponstatus[ASHTS_UNDERBARREL]=2;

		InitializeWepStats(false);
	}

	//returns the power of the load just fired
	static double Fire(actor caller, int choke=1) {
		double spread=7.;
		double speedfactor=1.;
		let hhh=RIreaper(caller.findinventory("RIReaper"));
		if (hhh)choke=hhh.weaponstatus[ASHTS_CHOKE];

		choke=clamp(choke, 0, 7);
		spread=6.5-0.5*choke;
		speedfactor=1.+0.02857*choke;

		double shotpower=frandom(0.9, 1.05);
		spread*=shotpower;
		speedfactor*=shotpower;
		HDBulletActor.FireBullet(caller,"HDB_wad");
		let p=HDBulletActor.FireBullet(caller,"HDB_00",
			spread:spread, speedfactor:speedfactor, amount:10
		);
		distantnoise.make(p,"world/shotgunfar");
		caller.A_StartSound("weapons/rprbang", CHAN_WEAPON);
		return shotpower;
	}

	action void A_FireReaper() {
		double shotpower=invoker.Fire(self);
		A_GunFlash();
		vector2 shotrecoil=(randompick(-1, 1)*1.4,-3.4);
		if (invoker.weaponstatus[ASHTS_AUTO]>0)shotrecoil=(randompick(-1, 1)*1.4,-3.4);
		shotrecoil*=shotpower;
		A_MuzzleClimb(0, 0, shotrecoil.x, shotrecoil.y, randompick(-1, 1)*shotpower,-0.3*shotpower);
		invoker.weaponstatus[ASHTS_CHAMBER]=2;
		invoker.shotpower=shotpower;
	}

	action bool brokenround() {
		if (!(invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_CHAMBERBROKEN)) {
			int rnd=
				(invoker.owner?1:10)
				+(invoker.weaponstatus[ASHTS_ZAUTO])
				+(invoker.weaponstatus[ASHTS_ZMAG]>100?10:0);
			if (random(0, 2000)<rnd) {
				invoker.weaponstatus[ASHTS_FLAGS]|=ASHTF_CHAMBERBROKEN;
			}
		}return invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_CHAMBERBROKEN;
	}

	override void failedpickupunload() {
		failedpickupunloadmag(ASHTS_MAG,"RIReapD20");
	}

	override void DropOneAmmo(int amt) {
		if (owner) {
			amt = clamp(amt, 1, 10);

			if (owner.countinv("HDShellAmmo")) {
				owner.A_DropInventory("HDShellAmmo", amt * 20);
			} else if (weaponstatus[ASHTS_BOXER]==1) {
				owner.A_DropInventory("RIReapM8", amt);
			} else {
				owner.A_DropInventory("RIReapD20", amt);
			}
		}
	}

	override void ForceBasicAmmo() {
		owner.A_TakeInventory("HDShellAmmo");
		owner.A_TakeInventory("RIReapD20");
		owner.A_GiveInventory("RIReapD20");
	}

	override string, double getpickupsprite() {
		return getbasepickupsprite()..""..getpickupspriteframe().."0", 0.5;
	}

	private clearscope string getbasepickupsprite() {
		switch (weaponstatus[ASHTS_UNDERBARREL]) {
			case 1:  return "ASHG";
			case 2:  return "ASHR";
			default: return "ASHT";
		}
	}

	private clearscope string getpickupspriteframe() {
		let hasBoxMag      = weaponstatus[ASHTS_BOXER];
		let hasMagLoaded   = weaponstatus[ASHTS_MAG] > -1;
		let hasZMMagLoaded = weaponstatus[ASHTS_ZMAG] > -1;

		switch (weaponstatus[ASHTS_UNDERBARREL]) {
			case 2:
				return hasZMMagLoaded
					? (hasMagLoaded
						? (hasBoxMag ? "E" : "A")
						: "B")
					: (hasMagLoaded
						? (hasBoxMag ? "C" : "D")
						: "F");
			default:
				return hasMagLoaded
					? (hasBoxMag ? "E" : "A")
					: "B";
		}
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl) {
		if (sb.hudlevel == 1) {

			let boxMagNext = hpl.countinv("RIReapM8")&(hdw.weaponstatus[ASHTS_BOXER] ^ hdw.weaponstatus[ASHTS_BOXEE])&1;

			// Draw Extra Drum Mags
			int nextdrumloaded=sb.GetNextLoadMag(hdmagammo(hpl.findinventory("RIReapD20")));
			if (nextdrumloaded>=20) {
				sb.drawimage("ASDMB0",(boxMagNext ? -61 : -51,-3), sb.DI_SCREEN_CENTER_BOTTOM, scale:(1, 1));
			} else if (nextdrumloaded<1) {
				sb.drawimage("ASDMA0",(boxMagNext ? -61 : -51,-3), sb.DI_SCREEN_CENTER_BOTTOM, alpha:nextdrumloaded?0.6:1., scale:(1, 1));
			} else sb.drawbar(
				"ASDMNORM","ASDMGREY",
				nextdrumloaded, 20,
				(boxMagNext ? -61 : -51,-3),-1,
				sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM
			);
			sb.drawnum(hpl.countinv("RIReapD20"), boxMagNext ? -58 : -43,-8, sb.DI_SCREEN_CENTER_BOTTOM, font.CR_BLACK);

			// Draw Extra Box Mags
			int nextmagloaded=sb.GetNextLoadMag(hdmagammo(hpl.findinventory("RIReapM8")));
			if (nextmagloaded>=8) {
				sb.drawimage("ASSMB0",(boxMagNext ? -51 : -61,-3), sb.DI_SCREEN_CENTER_BOTTOM, scale:(1, 1));
			} else if (nextmagloaded<1) {
				sb.drawimage("ASSMA0",(boxMagNext ? -51 : -61,-3), sb.DI_SCREEN_CENTER_BOTTOM, alpha:nextmagloaded?0.6:1., scale:(1, 1));
			} else sb.drawbar(
				"ASSMNORM","ASSMGREY",
				nextmagloaded, 20,
				(boxMagNext ? -51 : -61,-3),-1,
				sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM
			);
			sb.drawnum(hpl.countinv("RIReapM8"), boxMagNext ? -43 : -58,-8, sb.DI_SCREEN_CENTER_BOTTOM, font.CR_BLACK);

			// Draw Underbarrel Ammo
			switch (weaponstatus[ASHTS_UNDERBARREL]) {
				case 1:
					// Draw Extra Rocquettes
					sb.drawimage("ROQPA0",(-73,-4), sb.DI_SCREEN_CENTER_BOTTOM, scale:(0.6, 0.6));
					sb.drawnum(hpl.countinv("HDRocketAmmo"),-73,-8, sb.DI_SCREEN_CENTER_BOTTOM, font.CR_BLACK);
					break;
				case 2:

					// Draw Extra 4.26mm Mags
					int ZMnextmagloaded=sb.GetNextLoadMag(hdmagammo(hpl.findinventory("HD4mMag")));
					if (ZMnextmagloaded>50) {
						sb.drawimage("ZMAGA0",(-74,-4), sb.DI_SCREEN_CENTER_BOTTOM, scale:(2, 2));
					} else if (ZMnextmagloaded<1) {
						sb.drawimage("ZMAGC0",(-74,-4), sb.DI_SCREEN_CENTER_BOTTOM, alpha:ZMnextmagloaded?0.6:1., scale:(2, 2));
					} else sb.drawbar(
						"ZMAGNORM","ZMAGGREY",
						ZMnextmagloaded, 50,
						(-74,-4),-1,
						sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM
					);
					sb.drawnum(hpl.countinv("HD4mMag"),-73,-8, sb.DI_SCREEN_CENTER_BOTTOM, font.CR_BLACK);

					// Draw ZM Ammo
					int lod=clamp(hdw.weaponstatus[ASHTS_ZMAG]%100, 0, 50);
					if (hdw.weaponstatus[ASHTS_ZMAG]>100) {
						lod=random[shitgun](10, 99);
					}

					sb.drawnum(lod,-16,-10, sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT, Font.CR_RED);
					sb.drawwepcounter(
						hdw.weaponstatus[ASHTS_ZAUTO],
						-24,-5,
						"STSEMAUT","STFULAUT","STBURAUT"
					);
					sb.drawwepnum(lod, 50, posy:-2);
					break;
				default:
					break;
			}

			// Draw Fire Mode
			sb.drawwepcounter(
				hdw.weaponstatus[ASHTS_AUTO],
				-20,-17,
				"STSEMAUT","STFULAUT"
			);

			// Draw Drum Mag Status
			if (!weaponstatus[ASHTS_BOXER]) {

				// Draw Drum Mag Rounds
				if (hdw.weaponstatus[ASHTS_CHAMBER]==2) {
					for (int i=hdw.weaponstatus[ASHTS_MAG]-1;i>0;i--) {
						double RIrad=13; //circle radius
						double RIx=(RIrad-0)*cos((18*i)-95);
						double RIy=(RIrad-0)*sin((18*i)-95);
						sb.drawrect(-27-(-RIx*1)-2,-23-(-RIy*1)-2, 2, 2);
					}
				} else {
					for (int i=hdw.weaponstatus[ASHTS_MAG];i>0;i--) {
						double RIrad=13; //circle radius
						double RIx=(RIrad-0)*cos((18*i)-90);
						double RIy=(RIrad-0)*sin((18*i)-90);
						sb.drawrect(-27-(-RIx*1)-2,-23-(-RIy*1)-2, 2, 2);
					}
				}

			// Draw Box Mag Status
			} else {

				// Draw Box Mag
				if (hdw.weaponstatus[ASHTS_CHAMBER]==2) {
					for (int i=hdw.weaponstatus[ASHTS_MAG];i>0;i--) {
						double RIrad=37; //circle radius
						double RIx=(RIrad-0)*cos((3*i)-0);
						double RIy=(3*i)-90;
						sb.drawrect((-48-(-RIx*1))-2, (53-(-RIy*1))-2, 2, 2);
						sb.drawrect((-51-(-RIx*1))-4, (53-(-RIy*1))-2, 4, 2);
					}
				} else {
					for (int i=hdw.weaponstatus[ASHTS_MAG];i>0;i--) {
						double RIrad=37; //circle radius
						double RIx=(RIrad-0)*cos((3*i)-0);
						double RIy=(3*i)-90;
						sb.drawrect(-48-(-RIx*1)-2, 54-(-RIy*1)-2, 2, 2);
						sb.drawrect(-51-(-RIx*1)-4, 54-(-RIy*1)-2, 4, 2);
					}
				}
			}

			// Draw Chambered Rounds
			switch (weaponstatus[ASHTS_UNDERBARREL]) {

				// Draw Shell + Rocquette
				case 1:

					// Draw Chambered Shell
					if (hdw.weaponstatus[ASHTS_CHAMBER]==3) {
						HDCore.DrawSimpleShell(
							sb,
							Color(255, sb.sbColour.r, sb.sbColour.g, sb.sbColour.b),
							(-30, -22),
							3,
							1.0,
							sb.DI_SCREEN_CENTER_BOTTOM
						);
					} else if (hdw.weaponstatus[ASHTS_CHAMBER]==2) {
						// TODO:  Replace with HDCore Prefab of half-spent shell?
						sb.drawrect(-30-3,-25-2, 3, 2);
						sb.drawrect(-30-3,-22-2, 3, 2);
					} else if (hdw.weaponstatus[ASHTS_CHAMBER]==1) {
						HDCore.DrawSpentShell(
							sb,
							Color(255, sb.sbColour.r, sb.sbColour.g, sb.sbColour.b),
							(-30, -22),
							3,
							1.0,
							sb.DI_SCREEN_CENTER_BOTTOM
						);
					}

					// Draw Chambered Rocquette
					if (hdw.weaponstatus[0]&ASHTF_GZCHAMBER) {
						HDCore.DrawRocquette(
							sb, 
							Color(255, sb.sbColour.r, sb.sbColour.g, sb.sbColour.b),
							(-26, -22),
							3,
							1.0,
							sb.DI_SCREEN_CENTER_BOTTOM
						);
					}
					break;

				// Draw Shell
				default:

					// Draw Chambered Shell
					if (hdw.weaponstatus[ASHTS_CHAMBER]==3) {
						HDCore.DrawSimpleShell(
							sb,
							Color(255, sb.sbColour.r, sb.sbColour.g, sb.sbColour.b),
							(-29, -22),
							3,
							1.0,
							sb.DI_SCREEN_CENTER_BOTTOM
						);
					} else if (hdw.weaponstatus[ASHTS_CHAMBER]==2) {
						// TODO:  Replace with HDCore Prefab of half-spent shell?
						sb.drawrect(-26-3,-25-2, 3, 2);
						sb.drawrect(-26-3,-22-2, 3, 2);
					} else if (hdw.weaponstatus[ASHTS_CHAMBER]==1) {
						HDCore.DrawSpentShell(
							sb,
							Color(255, sb.sbColour.r, sb.sbColour.g, sb.sbColour.b),
							(-29, -22),
							3,
							1.0,
							sb.DI_SCREEN_CENTER_BOTTOM
						);
					}
					break;
			}
		}
	}

	override string gethelptext() {
		switch (weaponstatus[ASHTS_UNDERBARREL]) {
			case 1:
				return
					WEPHELP_FIRESHOOT
					..WEPHELP_ALTFIRE.."  Swap to Grenade Launcher\n"
					..WEPHELP_ALTRELOAD.."  Reload Grenade Launcher\n"
					..WEPHELP_RELOAD.."  Reload/Cycle bolt (Hold "..WEPHELP_FIREMODE.." to swap magazine types\)\n"
					..WEPHELP_FIREMODE.."  Destroy/Annihilate\n"
					..WEPHELP_MAGMANAGER
					..WEPHELP_UNLOADUNLOAD
				;
			case 2:
				return
					WEPHELP_FIRESHOOT
					..WEPHELP_ALTFIRE.."  Swap to Underbarrel ZM66\n"
					..WEPHELP_ALTRELOAD.."  Reload Underbarrel ZM66\n"
					..WEPHELP_RELOAD.."  Reload/Cycle bolt (Hold "..WEPHELP_FIREMODE.." to swap magazine types\)\n"
					..WEPHELP_FIREMODE.."  Destroy/Annihilate\n"
					..WEPHELP_MAGMANAGER
					..WEPHELP_UNLOADUNLOAD
				;
			default:
				return
					WEPHELP_FIRESHOOT
					..WEPHELP_ALTFIRE.."  Cycle Bolt\n"
					..WEPHELP_RELOAD.."  Reload/Cycle bolt (Hold "..WEPHELP_FIREMODE.." to swap magazine types\)\n"
					..WEPHELP_FIREMODE.."  Destroy/Annhilate\n"
					..WEPHELP_MAGMANAGER
					..WEPHELP_UNLOADUNLOAD
				;
		}
	}

	override string PickupMessage() {
		switch (weaponstatus[ASHTS_UNDERBARREL]) {
			case 1: return Stringtable.localize("$PICKUP_REAPER_GL");
			case 2: return Stringtable.localize("$PICKUP_REAPER_ZM");
			default: return Stringtable.localize("$PICKUP_REAPER");
		}
	}

	override void DrawSightPicture(
		HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl,
		bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot
	) {
		switch (hdw.weaponstatus[ASHTS_UNDERBARREL]) {
			case 1: DrawGLSightPicture(sb, hdw, hpl, sightbob, bob, fov, scopeview, hpc, whichdot);      break; // GL
			case 2: DrawZMSightPicture(sb, hdw, hpl, sightbob, bob, fov, scopeview, hpc, whichdot);      break; // ZM
			default: DrawNormalSightPicture(sb, hdw, hpl, sightbob, bob, fov, scopeview, hpc, whichdot); break; // None
		}
	}

	private ui void DrawGLSightPicture(
		HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl,
		bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot
	) {
		if (hdw.weaponstatus[0]&ASHTF_GLMODE) {
			sb.drawgrenadeladder(hdw.airburst, bob);
		} else {
			DrawNormalSightPicture(sb, hdw, hpl, sightbob, bob, fov, scopeview, hpc, whichdot);
		}
	}

	private ui void DrawZMSightPicture(
		HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl,
		bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot
	) {
		if (hdw.weaponstatus[0]&ASHTF_GLMODE) {
			int cx, cy, cw, ch;
			[cx, cy, cw, ch]=screen.GetClipRect();
			sb.SetClipRect(
				-16+bob.x,-4+bob.y, 32, 16,
				sb.DI_SCREEN_CENTER
			);
			vector2 bobb=bob*4;
			bobb.y=clamp(bobb.y,-8, 8);
			sb.drawimage(
				"RPRFGRN",(0,-11)+bobb, sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
				alpha:0.9
			);
			sb.SetClipRect(cx, cy, cw, ch);
			sb.drawimage(
				"RPRZBCK",(0, 0)+bob, sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
			);
		} else {
			int cx, cy, cw, ch;
			[cx, cy, cw, ch]=screen.GetClipRect();
			sb.SetClipRect(
				-16+bob.x,-4+bob.y, 32, 16,
				sb.DI_SCREEN_CENTER
			);
			vector2 bobb=bob*3;
			bobb.y=clamp(bobb.y,-8, 8);
			sb.drawimage(
				"RPRFGRN",(0,-11)+bobb, sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
				alpha:0.9
			);
			sb.SetClipRect(cx, cy, cw, ch);
			sb.drawimage(
				"RPRZBCK",(0,-11)+bob, sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
			);
		}
	}

	private ui void DrawNormalSightPicture(
		HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl,
		bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot
	) {
		if (hdw.weaponstatus[ASHTS_SIGHTS]==0) {
			int cx, cy, cw, ch;
			[cx, cy, cw, ch]=screen.GetClipRect();
			sb.SetClipRect(
				-16+bob.x,-4+bob.y, 32, 16,
				sb.DI_SCREEN_CENTER
			);
			vector2 bobb=bob*3;
			bobb.y=clamp(bobb.y,-8, 8);
				sb.drawimage(
				"RPRFRNT",(0,-11)+bobb, sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
				alpha:0.9
			);
				sb.SetClipRect(cx, cy, cw, ch);
				sb.drawimage(
				"TmpSBCK",(0,-11)+bob, sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
			);
		} else {
			int cx, cy, cw, ch;
			[cx, cy, cw, ch]=screen.GetClipRect();
			sb.SetClipRect(
				-16+bob.x,-4+bob.y, 32, 16,
				sb.DI_SCREEN_CENTER
			);
			vector2 bobb=bob*3;
			bobb.y=clamp(bobb.y,-8, 8);
				sb.drawimage(
				"RPRFGRN",(0,-11)+bobb, sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
				alpha:0.9
			);
				sb.SetClipRect(cx, cy, cw, ch);
				sb.drawimage(
				"RPRSBCK",(0,-11)+bob, sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
			);
		}
	}

	action void A_ReaperSpriteSelect() {
	    let psp = player.FindPSprite (PSP_Weapon);
        if (!psp) return;

		if (invoker.weaponstatus[ASHTS_BOXER]) {
			psp.frame = 0;
		} else {
			int ast = invoker.weaponstatus[ASHTS_MAG];

			if (ast >= 19) {
				psp.frame = 9;
			} else if (ast >= 18) {
				psp.frame = 8;
			} else if (ast >= 17) {
				psp.frame = 7;
			} else if (ast >= 16) {
				psp.frame = 6;
			} else if (ast >= 6) {
				psp.frame = 5;
			} else if (ast >= 5) {
				psp.frame = 4;
			} else if (ast >= 4) {
				psp.frame = 3;
			} else if (ast >= 3) {
				psp.frame = 2;
			} else if (ast >= 0) {
				psp.frame = 1;
			} else {
				psp.frame = 0;
			}
		}
	}

	states {

		// Selects
		select0:
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] && invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GLMODE,"select0rigren");
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			goto select0big;
		deselect0:
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] && invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GLMODE,"deselect0rigren");
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			goto deselect0big;

		// Underbarrel Selects
		select0rigren:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			goto select0big;
		deselect0rigren:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			goto deselect0big;

		// Ready States
		ready:
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GLMODE, 'readyUB');
			#### # 0 A_JumpIf(
				invoker.weaponstatus[ASHTS_UNDERBARREL] == 2
				&& invoker.weaponstatus[ASHTS_HEAT] > RILD_RPRZMCOOKOFF
				&& invoker.weaponstatus[0]&ASHTF_GZCHAMBER
				&& !(invoker.weaponstatus[0]&ASHTF_CHAMBERBROKEN),
				'cookoff'
			);
			#### # 0 A_SetCrosshair(21);
			#### # 1 A_WeaponReady(WRF_ALL);
			goto readyend;
		readyUB:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_JumpIf(
				invoker.weaponstatus[ASHTS_UNDERBARREL] == 2
				&& invoker.weaponstatus[ASHTS_HEAT] > RILD_RPRZMCOOKOFF
				&& invoker.weaponstatus[0]&ASHTF_GZCHAMBER
				&& !(invoker.weaponstatus[0]&ASHTF_CHAMBERBROKEN),
				'cookoff'
			);
			#### # 0 A_SetCrosshair(21);
			#### # 0 A_WeaponReady(WRF_ALL);
			#### # 1 {
				if (invoker.weaponstatus[ASHTS_ZAUTO] > 2) {
					invoker.weaponstatus[ASHTS_ZAUTO] = 2;
				}
			}
			goto readyend;

		// Mag Manager
		user3:
			#### # 3;
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] == 2 && invoker.weaponstatus[0]&ASHTF_GLMODE, "zmmagman");
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_BOXER], "boxmagman");
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_MagManager("RIReapD20");
			goto ready;
		boxmagman:
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_MagManager("RIReapM8");
			goto ready;
		zmmagman:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_MagManager("HD4mMag");
			goto ready;

		// Fire Mode Select
		user2:
		firemode:
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] == 1 && invoker.weaponstatus[0]&ASHTF_GLMODE, "abadjust");
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] == 2 && invoker.weaponstatus[0]&ASHTF_GLMODE, "zmfiremode");
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 3 {
				invoker.weaponstatus[ASHTS_BOXEE] = invoker.weaponstatus[ASHTS_BOXEE]|PressingReload();
			}
			#### # 0 A_JumpIf(PressingReload(), "reloadselect");
			#### # 1 {
				invoker.weaponstatus[ASHTS_AUTO] = !invoker.weaponstatus[ASHTS_AUTO];
			}
			goto nope;
		zmfiremode:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 {
				if (invoker.weaponstatus[ASHTS_ZAUTO] >= 2) {
					invoker.weaponstatus[ASHTS_ZAUTO] = 0;
				} else {
					invoker.weaponstatus[ASHTS_ZAUTO]++;
				}

				A_WeaponReady(WRF_NONE);
			}
			goto nope;

		// Fire States
		fire:
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] == 1 && invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GLMODE,"firefrag");
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] == 2 && invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GLMODE,"fireZM");
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
		fire2:
			#### JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 3;
			#### # 1 {
				if (invoker.weaponstatus[ASHTS_CHAMBER] > 2) {
					A_FireReaper();
				} else {
					setweaponstate("nope");
				}
			}
			#### # 1 offset(0, 40);
			#### # 0 {
				invoker.weaponstatus[ASHTS_CHAMBER] = 1;
			}
			#### # 0 A_JumpIf(invoker.shotpower > 0.901 && invoker.weaponstatus[ASHTS_BOXER], "rechamber");
			#### # 0 A_JumpIf(invoker.shotpower > 0.903, "rechamber");
			#### # 0 A_StartSound("weapons/riflejam", CHAN_WEAPON);
			goto ready;
		firefrag:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GZCHAMBER, 1);
			goto nope; //Note to tell Matt that the ZM's GL causes a flash even when unloaded
			#### # 2;
			#### # 1 A_Gunflash("nadeflash");
			#### # 2 offset(0, 15);
			goto nope;
		fireZM:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_JumpIf(invoker.weaponstatus[0]&ASHTF_CHAMBERBROKEN, "nope");
			#### # 2 {
				if (invoker.weaponstatus[ZM66S_AUTO]) {
					A_SetTics(3);
				}
			}
			goto shootgun;

		hold:
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] == 2 && invoker.weaponstatus[0]&ASHTF_GLMODE, 2);
			#### # 0 {
				if (
					// full auto
					invoker.weaponstatus[ASHTS_AUTO] == 2
				) {
					setweaponstate("fire2");
				} else if (
					// burst
					invoker.weaponstatus[ASHTS_AUTO] < 1
				) {
					setweaponstate("nope");
				}
			}
			goto fire;
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_ZAUTO] > 4, "nope");
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_ZAUTO], "shootgun");
			goto nope;


		rechamber:
			#### # 0 {
				//hunter shotpower used as refrence here, and i'm keeping this redundant check just for this
				if (invoker.weaponstatus[ASHTS_CHAMBER] == 1 && invoker.shotpower > 0.901) {
					vector3 cockdir;
					cockdir *= frandom(-500.5, 700.8);

					A_SpawnItemEx(
						"HDSpentShell",
						cos(pitch) * 8, frandom(0.0, 0.5), height - 10 - sin(pitch) * 8,
						vel.x + cockdir.x, vel.y + cockdir.y, vel.z + cockdir.z,
						0,
						SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
					);

					invoker.weaponstatus[ASHTS_CHAMBER] = 0;
					if (invoker.weaponstatus[ASHTS_MAG] > 0) {
						invoker.weaponstatus[ASHTS_MAG]--;
						invoker.weaponstatus[ASHTS_CHAMBER] = 3;
					}
				}

				if (invoker.weaponstatus[ASHTS_AUTO]==2) {
					A_SetTics(1);
				}

				A_WeaponReady(WRF_NOFIRE);
			}
			#### # 0 A_ReFire();
			goto ready;

		// Gun Flash Overlays
		flash:
			ASTF JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 {
				A_Light2();
				HDFlashAlpha(-32);
			}
			TNT1 A 1 A_ZoomRecoil(0.9);
			TNT1 A 0 A_Light0();
			TNT1 A 0 A_AlertMonsters();

			goto lightdone;
		nadeflash:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GZCHAMBER, 1);
			stop; // this does nothing (?now?) but I'll keep it here anyway~
			#### # 2 offset(0, 15) {
				A_FireHDGL();
				invoker.weaponstatus[ASHTS_FLAGS]&=~ASHTF_GZCHAMBER;
				A_StartSound("weapons/grenadeshot", CHAN_WEAPON);
				A_ZoomRecoil(0.95);
			}
			#### # 2 A_MuzzleClimb(
				0, 0, 0, 0,
				-1.2,-3.,
				-1.,-2.8
			);
			stop;
		zmflash:
			ASTM JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 bright {
				A_Light1();
				HDFlashAlpha(-16);
				A_StartSound("weapons/rifle", CHAN_WEAPON);
				A_ZoomRecoil(max(0.95, 1. - 0.05 * min(invoker.weaponstatus[ASHTS_ZAUTO], 3)));

				//shoot the bullet
				//copypaste any changes to spawnshoot as well!
				double brnd = invoker.weaponstatus[ASHTS_HEAT] * 0.01;
				HDBulletActor.FireBullet(
					self, "HDB_426",
					spread: brnd > 1.2
						? invoker.weaponstatus[ASHTS_HEAT] * 0.1
						: 0
				);

				A_MuzzleClimb(
					-frandom(0.1, 0.1),-frandom(0, 0.1),
					-0.2,-frandom(0.3, 0.4),
					-frandom(0.4, 1.4),-frandom(1.3, 2.6)
				);

				invoker.weaponstatus[ASHTS_FLAGS]&=~ASHTF_GZCHAMBER;
				invoker.weaponstatus[ASHTS_HEAT]+=random(3, 5);
				A_AlertMonsters();
			}
			goto lightdone;


		// TODO: Determine if still used
		unloadchamber:
			ASTI JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 4 A_JumpIf(invoker.weaponstatus[ASHTS_CHAMBER] < 1, "nope");
			#### # 10 {
				class<actor> which = invoker.weaponstatus[ASHTS_CHAMBER] > 1
					? "HDFumblingShell"
					: "HDSpentShell";

				invoker.weaponstatus[ASHTS_CHAMBER] = 0;

				A_SpawnItemEx(
					which,
					cos(pitch) * 10, 0, height - 8 - sin(pitch) * 10,
					vel.x, vel.y, vel.z,
					0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}
			goto readyend;


		loadchamber:
			ASTI JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_CHAMBER] > 0 || !countinv("HDShellAmmo"), "nope");
			#### # 1 offset(0, 34) A_StartSound("weapons/pocket", CHAN_WEAPON);
			#### # 1 offset(2, 36);
			#### # 1 offset(5, 40);
			#### # 4 offset(4, 39) {
				if (countinv("HDShellAmmo")) {
					A_TakeInventory("HDShellAmmo", 1, TIF_NOTAKEINFINITE);
					invoker.weaponstatus[ASHTS_CHAMBER] = 3;
					A_StartSound("weapons/smgchamber", CHAN_WEAPON);
				}
			}
			#### # 7 offset(5, 37);
			#### # 1 offset(2, 36);
			#### # 1 offset(0, 34);
			goto readyend;


		user4:
		unload:
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 {
				invoker.weaponstatus[ASHTS_FLAGS] |= ASHTF_JUSTUNLOAD;

				if (invoker.weaponstatus[0]&ASHTF_GLMODE) {
					if (invoker.weaponstatus[ASHTS_UNDERBARREL] == 1) {
						setweaponstate("unloadgrenade");
					} else {
						setweaponstate("zmunload");
					}
				} else if (invoker.weaponstatus[ASHTS_MAG] >= 0) {
					if (invoker.weaponstatus[ASHTS_BOXER] > 0) {
						setweaponstate("boxout");
					} else {
						setweaponstate("unmag");
					}
				} else if (invoker.weaponstatus[ASHTS_CHAMBER] > 0) {
					setweaponstate("prechamber");
				}
			}
			goto nope;


		altfire:
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] == 1, "altfiregl");
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] == 2, "altfirezm");
			#### # 0 A_WeaponBusy();
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_CHAMBER] < 3 && invoker.weaponstatus[ASHTS_MAG] > 0, "prechamber");
			#### # 0 {
				invoker.weaponstatus[0] &= ~ASHTF_JUSTUNLOAD;
			}
			#### # 0 {
				if (HDMagAmmo.NothingLoaded(self, "RIReapD20") || HDMagAmmo.NothingLoaded(self, "RIReapM8")) {
					if (
						invoker.weaponstatus[ASHTS_MAG] < 0
						&& countinv("HDShellAmmo")
					) {
						setweaponstate("prechamber");
					} else {
						setweaponstate("nope");
					}
				}
			}
		althold:
			#### # 1;
			#### # 0 A_JumpIf(PressingReload(), "loadchamber");
			#### # 0 A_Refire();
			goto ready;

		altfiregl:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 offset(6, 0) {
				invoker.weaponstatus[0] ^= ASHTF_GLMODE;
				invoker.airburst = 0;
				A_SetCrosshair(21);
				A_SetHelpText();
			}
			goto nope;
		altfirezm:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 offset(6, 0) {
				invoker.weaponstatus[0] ^= ASHTF_GLMODE;
				A_SetCrosshair(21);
				A_StartSound("weapons/pocket", CHAN_WEAPON);
				A_SetHelpText();
			}
			goto nope;

		reload:
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_CHAMBER] < 3 && invoker.weaponstatus[ASHTS_MAG] > 0, "prechamber");
			#### # 3 {
				invoker.weaponstatus[ASHTS_BOXEE] = invoker.weaponstatus[ASHTS_BOXEE]|PressingFiremode();
			}
			#### # 0 A_JumpIf(PressingFiremode(), "reloadselect");
			#### # 0 {
				invoker.weaponstatus[0] &= ~ASHTF_JUSTUNLOAD;

				if (invoker.weaponstatus[ASHTS_BOXER]) {
					if (invoker.weaponstatus[ASHTS_MAG] >= 8) {
						setweaponstate("nope");
						return;
					}
				} else {
					if (invoker.weaponstatus[ASHTS_MAG] >= 20) {
						setweaponstate("nope");
						return;
					}
				}

				if (HDMagAmmo.NothingLoaded(self,"RIReapD20")) {
					if (HDMagAmmo.NothingLoaded(self,"RIReapM8")) {
						setweaponstate("nope");
					} else {
						invoker.weaponstatus[ASHTS_BOXEE] = 1;
						setweaponstate("reloadselect");
					}
				} else if (HDMagAmmo.NothingLoaded(self,"RIReapM8")) {
					if (HDMagAmmo.NothingLoaded(self,"RIReapD20")) {
						setweaponstate("nope");
					} else {
						invoker.weaponstatus[ASHTS_BOXEE] = 1;
						setweaponstate("reloadselect");
					}
				}
			}
		reloadselect:
			#### # 0 {
				invoker.weaponstatus[0] &= ~ASHTF_JUSTUNLOAD;
				invoker.weaponstatus[ASHTS_BOXEE] = (invoker.weaponstatus[ASHTS_BOXEE]|PressingFiremode())&1;
			}
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_BOXER], "boxout");
		unmag:
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 offset(0, 24) A_SetCrosshair(21);
			#### # 2 offset(2, 28);
			ASTB JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 3 offset(4, 32) A_StartSound("weapons/rprdrmot", CHAN_WEAPON);
			ASTC JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 5 offset(6, 36);
			ASTD JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 5 offset(8, 42) A_MuzzleClimb(0.3, 0.4);
			ASTE JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 5 offset(8, 42);
			ASTZ A 0 offset(8, 42) A_StartSound("weapons/smgmagmove", CHAN_WEAPON);
			#### # 5 offset(8, 42);
			#### # 0 {
				int magamt = invoker.weaponstatus[ASHTS_MAG];
				if (magamt < 0) {
					setweaponstate("magout");
					return;
				}

				invoker.weaponstatus[ASHTS_MAG] = -1;

				if (
					!(PressingUnload() || PressingReload())
					|| A_JumpIfInventory("RIReapD20", 0, "null")
				) {
					HDMagAmmo.SpawnMag(self, "RIReapD20", magamt);
					setweaponstate("magout");
				} else {
					HDMagAmmo.GiveMag(self, "RIReapD20", magamt);
					A_StartSound("weapons/pocket", CHAN_WEAPON);
					setweaponstate("pocketmag");
				}
			}
		boxout:
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 offset(0, 24) A_SetCrosshair(21);
			#### # 2 offset(2, 28);
			ASTB JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 3 offset(4, 32) A_StartSound("weapons/rprdrmot", CHAN_WEAPON);
			ASTC JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 4 offset(6, 36);
			ASTD JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 4 offset(8, 42) A_MuzzleClimb(0.3, 0.4);
			ASTE JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 4 offset(8, 42);
			ASTZ A 0 offset(8, 42) A_StartSound("weapons/smgmagmove", CHAN_WEAPON);
			#### # 4 offset(8, 42);
			#### # 0 {
				int magamt = invoker.weaponstatus[ASHTS_MAG];
				if (magamt < 0) {
					setweaponstate("magout");
					return;
				}

				invoker.weaponstatus[ASHTS_MAG] = -1;

				if (
					!(PressingUnload() || PressingReload())
					|| A_JumpIfInventory("RIReapM8", 0, "null")
				) {
					HDMagAmmo.SpawnMag(self, "RIReapM8", magamt);
					setweaponstate("magout");
				} else {
					HDMagAmmo.GiveMag(self, "RIReapM8", magamt);
					A_StartSound("weapons/pocket", CHAN_WEAPON);
					setweaponstate("pocketmag");
				}
			}
		pocketmag:
			ASTZ A 2 offset(8, 42);
			#### # 7 offset(8, 42) A_StartSound("weapons/pocket", CHAN_WEAPON);
			#### # 7 offset(8, 42) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			#### # 7 offset(8, 42) A_StartSound("weapons/pocket", CHAN_WEAPON);
			#### # 7 offset(8, 42) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
		magout:
			#### # 0 A_JumpIf(invoker.weaponstatus[0]&ASHTF_JUSTUNLOAD, "reloadend");
			#### # 0 A_JumpIf((!HDMagAmmo.NothingLoaded(self,"RIReapM8"))&(invoker.weaponstatus[ASHTS_BOXER] ^ invoker.weaponstatus[ASHTS_BOXEE])&1, "loadboxmag");
			goto loadmag;

		loadmag:
			#### # 0 A_StartSound("weapons/pocket", CHAN_WEAPON);
			ASTZ A 10 offset(8, 42);
			#### # 0 {
				let mmm = hdmagammo(findinventory("RIReapD20"));
				if (mmm) {
					invoker.weaponstatus[ASHTS_BOXER] = 0;
					invoker.weaponstatus[ASHTS_MAG] = mmm.TakeMag(true);
					A_StartSound("weapons/smgmagclick", CHAN_BODY);
				}
			}
			ASTE JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 6 offset(8, 42) A_MuzzleClimb(frandom(0.2,-0.8), frandom(-0.2, 0.4));
			ASTD JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 6 offset(8, 42) A_MuzzleClimb(frandom(0.2,-0.8), frandom(-0.2, 0.4));
			#### # 0 A_StartSound("weapons/rprdrmin", CHAN_BODY);
			ASTC JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 6 offset(6, 36);
			goto reloadend;

		loadboxmag:
			#### # 0 A_StartSound("weapons/pocket", CHAN_WEAPON);
			ASTZ A 5 offset(8, 42);
			#### # 0 {
				let mmm = hdmagammo(findinventory("RIReapM8"));
				if (mmm) {
					invoker.weaponstatus[ASHTS_BOXER] = 1;
					invoker.weaponstatus[ASHTS_MAG] = mmm.TakeMag(true);
					A_StartSound("weapons/smgmagclick", CHAN_BODY);
				}
			}
			ASTE JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 2 offset(8, 42) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			ASTD JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 2 offset(8, 42) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			#### # 0 A_StartSound("weapons/rprdrmin", CHAN_BODY);
			ASTC JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 2 offset(6, 36);
			goto reloadend;

		prechamber:
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 3 offset(4, 24);
			#### # 4 offset(4, 28);
			ASTB JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 4 offset(4, 32);
			#### # 0 offset(4, 32) A_JumpIf(invoker.weaponstatus[0]&ASHTF_JUSTUNLOAD, "unloaderchamber");
		chamber:
			ASTG JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 4 offset(6, 36);
			ASTH JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 3 offset(6, 36) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			#### # 0 A_StartSound("weapons/rprbolt", CHAN_WEAPON);
			#### # 2 offset(8, 36);
			ASTI JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 2 offset(10, 36);
			#### # 2 offset(10, 36) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			#### # 0 offset(10, 36) {
				if (invoker.weaponstatus[ASHTS_CHAMBER] > 0) {
					class<actor> which = invoker.weaponstatus[ASHTS_CHAMBER] > 1
						? "HDFumblingShell"
						: "HDSpentShell";

					A_SpawnItemEx(
						which,
						cos(pitch) * 10, 0, height - 8 - sin(pitch) * 10,
						vel.x, vel.y, vel.z,
						0,
						SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
					);
				}

				if (invoker.weaponstatus[ASHTS_MAG] > 0) {
					invoker.weaponstatus[ASHTS_MAG]--;
					invoker.weaponstatus[ASHTS_CHAMBER] = 3;
				}
			}
			ASTH JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 2 offset(8, 36);
			ASTG JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 2 offset(6, 36);
			goto reloadendend;
		unloaderchamber:
			ASTG JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 4 offset(6, 36);
			ASTH JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 3 offset(6, 36) A_MuzzleClimb(frandom(0.2,-0.8), frandom(-0.2, 0.4));
			#### # 0 A_StartSound("weapons/rprbolt", CHAN_WEAPON);
			#### # 2 offset(8, 36);
			ASTI JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 2 offset(10, 36);
			#### # 2 offset(10, 36) A_MuzzleClimb(frandom(0.2,-0.8), frandom(-0.2, 0.4));
			#### # 0 offset(10, 36) {
				class<actor> which = invoker.weaponstatus[ASHTS_CHAMBER] > 1
					? "HDFumblingShell"
					: "HDSpentShell";

				A_SpawnItemEx(
					which,
					cos(pitch) * 10, 0, height - 8 - sin(pitch) * 10,
					vel.x, vel.y, vel.z,
					0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);

				invoker.weaponstatus[ASHTS_CHAMBER] = 0;
			}
			ASTG JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 2 offset(8, 36);
			ASTH JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 2 offset(6, 36);
			goto reloadendend;
		reloadend:
			ASTC JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 3 offset(6, 36);
			ASTB JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 3 offset(6, 36) A_JumpIf(invoker.weaponstatus[ASHTS_CHAMBER] < 3 && invoker.weaponstatus[ASHTS_MAG] > 0, "chamber");
		reloadendend:
			ASTB JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 3 offset(4, 32) A_MuzzleClimb(frandom(0.2,-0.8), frandom(-0.2, 0.4));
			#### # 3 offset(2, 28);
			ASTA JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 3 offset(0, 24);
			#### # 0 {
				invoker.weaponstatus[ASHTS_BOXEE] = 0;
				invoker.weaponstatus[ASHTS_BOXER] = invoker.weaponstatus[ASHTS_BOXER]&(invoker.weaponstatus[ASHTS_MAG] > -1);
			}
			goto nope;

		altreload:
			#### # 0 {
				invoker.weaponstatus[ASHTS_FLAGS] &= ~ASHTF_JUSTUNLOAD;
			}
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] == 1, "altreloadgl");
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] == 2, "altreloadzm");
			goto nope;

		altreloadgl:
			#### # 0 A_JumpIf(!(invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GZCHAMBER)&&countinv("HDRocketAmmo"),"unloadgrenade");
			goto nope;
		altreloadzm:
			#### # 0 {
				invoker.weaponstatus[ASHTS_FLAGS] &= ~ASHTF_JUSTUNLOAD;
			}
			#### # 0 A_JumpIf( // full mag, no jam, not unload-only - why hit reload at all?
				!invoker.weaponstatus[0]&ASHTF_CHAMBERBROKEN
				&& invoker.weaponstatus[ASHTS_ZMAG] % 100 >= 50
				&& !invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_JUSTUNLOAD,
				"nope");
			#### # 0 {
				// if jammed, treat as unloading
				if (
					invoker.weaponstatus[ASHTS_ZMAG] < 0
					&& invoker.weaponstatus[0]&ASHTF_CHAMBERBROKEN
				) {
					invoker.weaponstatus[ASHTS_FLAGS] |= ASHTF_JUSTUNLOAD;
					setweaponstate("ZMunloadchamber");
				}
			}
			#### # 0 A_JumpIf(!HDMagAmmo.NothingLoaded(self,"HD4mMag"), "unloadmag");
			goto nope;

		// unload is also reload. Genius
		unloadgrenade:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 {
				A_SetCrosshair(21);
				A_MuzzleClimb(-0.3,-0.3);
			}
			ASTJ JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 2 offset(0, 34);
			#### # 1 offset(4, 38) {
				A_MuzzleClimb(-0.3,-0.3);
			}
			#### # 2 offset(8, 48) {
				A_StartSound("weapons/grenopen", 5);
				A_MuzzleClimb(-0.3,-0.3);

				if (invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GZCHAMBER) {
					A_StartSound("weapons/grenreload", CHAN_WEAPON);
				}
			}
			ASTK JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 10 offset(10, 49) {
				if (!(invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GZCHAMBER)) {
					if (!(invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_JUSTUNLOAD)) {
						A_SetTics(3);
					}

					return;
				}

				invoker.weaponstatus[ASHTS_FLAGS] &= ~ASHTF_GZCHAMBER;

				if (
					!PressingUnload()
					|| A_JumpIfInventory("HDRocketAmmo", 0, "null")
				) {
					A_SpawnItemEx(
						"HDRocketAmmo",
						cos(pitch) * 10, 0, height - 10 - 10 * sin(pitch),
						vel.x, vel.y, vel.z,
						0,
						SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
					);
				} else {
					A_StartSound("weapons/pocket", 5);
					A_GiveInventory("HDRocketAmmo", 1);
					A_MuzzleClimb(frandom(0.8, -0.2), frandom(0.4, -0.2));
				}
			}
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_JUSTUNLOAD, "greloadend");
		loadgrenade:
			#### # 4 offset(10, 50) A_StartSound("weapons/pocket", CHAN_WEAPON);
			#### # 8 offset(10, 50) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### # 8 offset(10, 50) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### # 8 offset(10, 50) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### # 18 offset(8, 50) {
				A_TakeInventory("HDRocketAmmo", 1, TIF_NOTAKEINFINITE);
				invoker.weaponstatus[ASHTS_FLAGS] |= ASHTF_GZCHAMBER;
				A_StartSound("weapons/grenreload", CHAN_WEAPON);
			}
		greloadend:
			ASTJ JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 4 offset(4, 44) A_StartSound("weapons/grenopen", CHAN_WEAPON);
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 offset(0, 40);
			#### # 1 offset(0, 34) A_MuzzleClimb(frandom(-2.4, 0.2), frandom(-1.4, 0.2));
			goto nope;


		// Underbarrel ZM States
		jam:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 offset(-1, 36) {
				A_StartSound("weapons/riflejam", CHAN_WEAPON);
				invoker.weaponstatus[0]|=ASHTF_CHAMBERBROKEN;
				invoker.weaponstatus[ASHTS_FLAGS] &= ~ASHTF_GZCHAMBER;
			}
			#### # 1 offset(1, 30) A_StartSound("weapons/riflejam", 6);
			goto nope;

		shootgun:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 {
				if (
					//can neither shoot nor chamber
					invoker.weaponstatus[0]&ASHTF_CHAMBERBROKEN
					||(
						!(invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GZCHAMBER)
						&& invoker.weaponstatus[ASHTS_ZMAG] < 1
					)
				) {
					setweaponstate("nope");
				} else if (!(invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GZCHAMBER)) {
					//no shot but can chamber
					setweaponstate("chamber_premanual");
				} else {
					A_GunFlash("ZMflash");
					A_WeaponReady(WRF_NONE);
					if (invoker.weaponstatus[ASHTS_ZAUTO]>=2)invoker.weaponstatus[ASHTS_ZAUTO]++;
				}
			}
		zmchamber:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_ZMAG] < 1, "nope");
			#### # 2 offset(0, 32) {
				if (invoker.weaponstatus[ASHTS_ZMAG] % 100 > 0) {
					if (invoker.weaponstatus[ASHTS_ZMAG] == 51) {
						invoker.weaponstatus[ASHTS_ZMAG] = 50;
					}

					invoker.weaponstatus[ASHTS_ZMAG]--;
					invoker.weaponstatus[ASHTS_FLAGS] |= ASHTF_GZCHAMBER;
				} else {
					invoker.weaponstatus[ASHTS_ZMAG] = min(invoker.weaponstatus[ASHTS_ZMAG], 0);
					A_StartSound("weapons/rifchamber", 5);
				}

				if (brokenround()) {
					setweaponstate("jam");
					return;
				}

				if (!invoker.weaponstatus[ASHTS_ZAUTO]) {
					A_SetTics(1);
				} else if (invoker.weaponstatus[ASHTS_ZAUTO] > 1) {
					A_SetTics(0);
				} else if (invoker.weaponstatus[ASHTS_ZAUTO] > 4) {
					setweaponstate("nope");
				}

				A_WeaponReady(WRF_NOFIRE); //not WRF_NONE: switch to drop during cookoff
			}
			#### # 0 A_JumpIf(
				invoker.weaponstatus[ASHTS_HEAT] > RILD_RPRZMCOOKOFF
				&& invoker.weaponstatus[0]&ASHTF_GZCHAMBER
				&& !invoker.weaponstatus[0]&ASHTF_CHAMBERBROKEN,
				"cookoff"
			);
			#### # 0 A_Refire();
			goto ready;

		cookoffaltfirelayer:
			TNT1 AAA 1 {
				if (JustPressed(BT_ALTFIRE)) {
					invoker.weaponstatus[0] ^= ASHTF_GLMODE;
					A_SetTics(10);
				} else if (JustPressed(BT_ATTACK) && invoker.weaponstatus[0]&ASHTF_GLMODE) {
					A_Overlay(11, "fire2");
				}
			}
			stop;
		cookoff:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 {
				A_ClearRefire();

				if (
					(invoker.weaponstatus[ASHTS_ZMAG] >= 0)      // something to detach
					&& (PressingAltReload() || PressingUnload()) // trying to detach
				) {
					A_StartSound("weapons/rifleclick2", CHAN_WEAPON);
					A_StartSound("weapons/rifleload", 5);

					HDMagAmmo.SpawnMag(self, "HD4mMag", invoker.weaponstatus[ASHTS_ZMAG]);

					invoker.weaponstatus[ASHTS_ZMAG] = -1;
				}

				setweaponstate("shootgun");
			}
		chamber_premanual:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 offset(0, 33);
			#### # 1 offset(-3, 34);
			#### A 1 offset(-8, 37);
			goto ZMchamber_manual;

		zmunload:
			#### # 0 {
				invoker.weaponstatus[ASHTS_FLAGS] |= ASHTF_JUSTUNLOAD;

				if (
					invoker.weaponstatus[ASHTS_ZMAG] >= 0
				) {
					setweaponstate("unloadmag");
				} else if (
					invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GZCHAMBER
					|| invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_CHAMBERBROKEN
				) {
					setweaponstate("ZMunloadchamber");
				} else {
					setweaponstate("unloadmag");
				}
			}
		unloadmag:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 offset(0, 33);
			#### # 1 offset(-3, 34);
			#### # 1 offset(-8, 37);
			ASTJ JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 2 offset(-11, 39) {
				// no mag, skip unload
				if (invoker.weaponstatus[ASHTS_ZMAG] < 0) {
					setweaponstate("ZMmagout");
				}

				if (invoker.weaponstatus[0]&ASHTF_CHAMBERBROKEN) {
					invoker.weaponstatus[ASHTS_FLAGS] |= ASHTF_JUSTUNLOAD;
				}

				A_SetPitch(pitch - 0.3, SPF_INTERPOLATE);
				A_SetAngle(angle - 0.3, SPF_INTERPOLATE);
				A_StartSound("weapons/rifleclick2", CHAN_WEAPON);
			}
			ASTK JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 4 offset(-12, 40) {
				A_SetPitch(pitch - 0.3, SPF_INTERPOLATE);
				A_SetAngle(angle - 0.3, SPF_INTERPOLATE);
				A_StartSound("weapons/rifleload", CHAN_WEAPON);
			}
			#### # 20 offset(-14, 44) {
				int inmag = invoker.weaponstatus[ASHTS_ZMAG] % 100;
				invoker.weaponstatus[ASHTS_ZMAG] = -1;

				if (
					!(PressingUnload() || PressingAltReload())
					|| A_JumpIfInventory("HD4mMag", 0, "null")
				) {
					HDMagAmmo.SpawnMag(self,"HD4mMag", inmag);
					A_SetTics(1);
				} else {
					HDMagAmmo.GiveMag(self,"HD4mMag", inmag);
					A_StartSound("weapons/pocket", CHAN_WEAPON);

					if (inmag < 51) {
						A_Log(HDCONST_426MAGMSG, true);
					}
				}
			}
		ZMmagout:
			ASTK JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 {
				if (
					invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_JUSTUNLOAD
					||!countinv("HD4mMag")
				)setweaponstate("ZMreloadend");
			}
		ZMloadmag:
			ASTK JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 12 {
				let zmag = HD4mMag(findinventory("HD4mMag"));
				if (!zmag) {
					setweaponstate("reloadend");
					return;
				}

				A_StartSound("weapons/pocket", CHAN_WEAPON);

				if (zmag.DirtyMagsOnly()) {
					invoker.weaponstatus[0]|=ASHTF_LOADINGDIRTY;
				} else {
					invoker.weaponstatus[0] &= ~ASHTF_LOADINGDIRTY;
					A_SetTics(10);
				}
			}
			#### # 2 A_JumpIf(invoker.weaponstatus[0]&ASHTF_LOADINGDIRTY, "loadmagdirty");
		loadmagclean:
			ASTK JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 8 offset(-15, 45) A_StartSound("weapons/rifleload", CHAN_WEAPON);
			ASTJ JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 offset(-14, 44) {
				let zmag = HD4mMag(findinventory("HD4mMag"));
				if (!zmag) {
					setweaponstate("reloadend");
					return;
				}

				if (zmag.DirtyMagsOnly()) {
					setweaponstate("loadmagdirty");
					return;
				}

				invoker.weaponstatus[ASHTS_ZMAG] = zmag.TakeMag(true);
				A_StartSound("weapons/rifleclick2", CHAN_WEAPON);
			}
			goto ZMchamber_manual;
		loadmagdirty:
			ASTJ JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 0 {
				if (PressingReload()) {
					invoker.weaponstatus[0] |= ASHTF_STILLPRESSINGRELOAD;
				} else {
					invoker.weaponstatus[0] &= ~ASHTF_STILLPRESSINGRELOAD;
				}
			}
			#### # 3 offset(-15, 45)A_StartSound("weapons/rifleload", CHAN_WEAPON);
			#### # 1 offset(-15, 42)A_WeaponMessage(HDCONST_426MAGMSG, 70);
			#### # 1 offset(-15, 41) {
				bool prr=PressingAltReload();
				if (
					prr
					&&!(invoker.weaponstatus[0]&ASHTF_STILLPRESSINGRELOAD)
				) {
					setweaponstate("reallyloadmagdirty");
				} else if (!PressingAltReload()) {
					invoker.weaponstatus[0]&=~ASHTF_STILLPRESSINGRELOAD;
				}
			}
			goto nope;
		reallyloadmagdirty:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 offset(-14, 44)A_StartSound("weapons/rifleclick2", CHAN_WEAPON);
			#### # 8 offset(-18, 50) {
				let zmag=HD4mMag(findinventory("HD4mMag"));
				if (!zmag) {setweaponstate("reloadend");return;}
				invoker.weaponstatus[ASHTS_ZMAG]=zmag.TakeMag(true)+100;
				A_MuzzleClimb(
					-frandom(0.4, 0.6), frandom(2., 3.)
					-frandom(0.2, 0.3), frandom(1., 1.6)
				);
				A_StartSound("weapons/rifleclick2", 6);
				A_StartSound("weapons/smack", 7);

				string realmessage=HDCONST_426MAGMSG;
				realmessage=realmessage.left(random(13, 20));
				realmessage.appendformat("\cgFUCK YOURSELF. \cj--mgmt.");
				A_WeaponMessage(realmessage, 70);
			}
			#### # 4 offset(-17, 49);
			// goto ZMchamber_manual;
		ZMchamber_manual:
			ASTJ JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 4 offset(-15, 43) {
				if (!invoker.weaponstatus[ASHTS_ZMAG]%100) {
					invoker.weaponstatus[ASHTS_ZMAG]=0;
				}

				if (
					!(invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GZCHAMBER)
					&& !(invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GZCHAMBER)
					&& invoker.weaponstatus[ASHTS_ZMAG]%100>0
				) {
					A_StartSound("weapons/rifleclick");

					if (invoker.weaponstatus[ASHTS_ZMAG] == 51) {
						invoker.weaponstatus[ASHTS_ZMAG] = 50;
					} else {
						invoker.weaponstatus[ASHTS_ZMAG]--;
					}

					invoker.weaponstatus[ASHTS_FLAGS]|=ASHTF_GZCHAMBER;
					brokenround();
				} else {
					setweaponstate("ZMreloadend");
				}
				A_WeaponBusy();
			}
			goto nope;
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 4 offset(-14, 45);
			goto reloadend;

		ZMreloadend:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 2 offset(-11, 39);
			#### # 1 offset(-8, 37) A_MuzzleClimb(frandom(0.2,-2.4), frandom(0.2,-1.4));
			#### # 1 offset(-3, 34);
			#### # 1 offset(0, 33);
			goto nope;


		ZMunloadchamber:
			ASTL JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 1 offset(-3, 34);
			#### # 1 offset(-9, 39);
			#### # 3 offset(-19, 44) A_MuzzleClimb(frandom(-0.4, 0.4), frandom(-0.4, 0.4));
			ASTJ JIHGFEDCBA 0 A_ReaperSpriteSelect();
			#### # 2 offset(-16, 42) {
				A_MuzzleClimb(frandom(-0.4, 0.4), frandom(-0.4, 0.4));
				if (
					invoker.weaponstatus[ASHTS_FLAGS]&ASHTF_GZCHAMBER
					&&!(invoker.weaponstatus[0]&ASHTF_CHAMBERBROKEN)
				) {
					A_SpawnItemEx(
						"ZM66DroppedRound",
						0, 0, 20,
						random(4, 7), random(-2, 2), random(-2, 1),
						0,
						SXF_NOCHECKPOSITION
					);

					invoker.weaponstatus[ASHTS_FLAGS]&=~ASHTF_GZCHAMBER;
					A_StartSound("weapons/rifleclick2", CHAN_WEAPON);
				} else if (!random(0, 4)) {
					invoker.weaponstatus[0]&=~ASHTF_CHAMBERBROKEN;
					invoker.weaponstatus[ASHTS_FLAGS]&=~ASHTF_GZCHAMBER;

					A_StartSound("weapons/rifleclick");

					for (int i = 0; i < 3; i++) {
						A_SpawnItemEx(
							"TinyWallChunk",
							0, 0, 20,
							random(4, 7), random(-2, 2), random(-2, 1),
							0,
							SXF_NOCHECKPOSITION
						);
				}

					if (!random(0, 5)) {
						A_SpawnItemEx("HDSmokeChunk", 12, 0, height-12, 4, frandom(-2, 2), frandom(2, 4));
					}
				} else if (invoker.weaponstatus[0]&ASHTF_CHAMBERBROKEN) {
					A_StartSound("weapons/smack", CHAN_WEAPON);
				}
			}
			goto reloadend;


		// Spawn States
		spawn:
			ASHT DCBA 0;
			ASHG DCBA 0;
			ASHR FEDCBA 0;
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] == 1,"spawngl");
			#### # 0 A_JumpIf(invoker.weaponstatus[ASHTS_UNDERBARREL] == 2,"spawnzm");
		spawnnormal:
			ASHT A -1 nodelay {
				if (invoker.weaponstatus[ASHTS_MAG]<0)frame=1;
				if (invoker.weaponstatus[ASHTS_BOXER]==1&&invoker.weaponstatus[ASHTS_MAG]>=0)frame=4;
			}
		spawngl:
			ASHG A -1 nodelay {
				if (invoker.weaponstatus[ASHTS_MAG]<0)frame=1;
				if (invoker.weaponstatus[ASHTS_BOXER]==1&&invoker.weaponstatus[ASHTS_MAG]>=0)frame=4;
			}
		spawnzm:
			ASHR A -1 nodelay {
				// A Drum 450
				// B -Drum 450
				// C Drum -450
				// D -Drum -450
				// E Stick 450
				// F stick -450
				if (invoker.weaponstatus[ASHTS_BOXER]==0&&invoker.weaponstatus[ASHTS_MAG]>-1&&invoker.weaponstatus[ASHTS_ZMAG]>-1)frame=0;
				if (invoker.weaponstatus[ASHTS_BOXER]==0&&invoker.weaponstatus[ASHTS_MAG]<0&&invoker.weaponstatus[ASHTS_ZMAG]>-1)frame=1;
				if (invoker.weaponstatus[ASHTS_BOXER]==1&&invoker.weaponstatus[ASHTS_MAG]>-1&&invoker.weaponstatus[ASHTS_ZMAG]>-1)frame=4;
				if (invoker.weaponstatus[ASHTS_BOXER]==0&&invoker.weaponstatus[ASHTS_MAG]>-1&&invoker.weaponstatus[ASHTS_ZMAG]<0)frame=2;
				if (invoker.weaponstatus[ASHTS_BOXER]==0&&invoker.weaponstatus[ASHTS_MAG]<0&&invoker.weaponstatus[ASHTS_ZMAG]<0)frame=3;
				if (invoker.weaponstatus[ASHTS_BOXER]==1&&invoker.weaponstatus[ASHTS_MAG]>-1&&invoker.weaponstatus[ASHTS_ZMAG]<0)frame=5;
			}
			#### # 0 {
				//don't jam just because
				if (
					!(invoker.weaponstatus[0]&ASHTF_GZCHAMBER)
					&&!(invoker.weaponstatus[0]&ASHTF_CHAMBERBROKEN)
					&&invoker.weaponstatus[ASHTS_ZMAG]>0
					&&invoker.weaponstatus[ASHTS_ZMAG]<51
				) {
					invoker.weaponstatus[ASHTS_ZMAG]--;
					invoker.weaponstatus[0]|=ASHTF_GZCHAMBER;
					brokenround();
				}

			}
			#### # 0 A_JumpIf(
				invoker.weaponstatus[0]&ASHTF_GZCHAMBER
				&&!(invoker.weaponstatus[0]&ASHTF_CHAMBERBROKEN)
				&&invoker.weaponstatus[ASHTS_HEAT]>RILD_RPRZMCOOKOFF,
				"spawnshoot"
			);
		spawnshoot:
			#### # 1 bright light("SHOT") {
				sprite = getspriteindex("ASHRA0");

				//shoot the bullet
				//copy any changes to flash as well!
				double brnd=invoker.weaponstatus[ASHTS_HEAT]*0.01;
				HDBulletActor.FireBullet(self,"HDB_426",
					spread:brnd>1.2?invoker.weaponstatus[ASHTS_HEAT]*0.1:0
				);

				A_ChangeVelocity(frandom(-0.4, 0.1), frandom(-0.1, 0.08), 1, CVF_RELATIVE);
				A_StartSound("weapons/rifle", CHAN_VOICE);
				invoker.weaponstatus[ASHTS_HEAT]+=random(3, 5);
				angle+=frandom(2,-7);
				pitch+=frandom(-4, 4);
			}
			#### # 2 {
				if (invoker.weaponstatus[ASHTS_ZAUTO]>1)A_SetTics(0);
				invoker.weaponstatus[0]&=~(ASHTF_GZCHAMBER|ASHTF_CHAMBERBROKEN);
				if (invoker.weaponstatus[ASHTS_ZMAG]%100>0) {
					invoker.weaponstatus[ASHTS_ZMAG]--;
					invoker.weaponstatus[0]|=ASHTF_GZCHAMBER;
					brokenround();
				}
			}
			goto spawn;
	}

	override void InitializeWepStats(bool idfa) {
		weaponstatus[ASHTS_MAG] = weaponstatus[ASHTS_BOXER] ? 8 : 20;
		weaponstatus[ASHTS_CHAMBER] = 3;
		weaponstatus[ASHTS_BOXEE] = 0;
		if (!idfa)weaponstatus[ASHTS_AUTO] = 0;

		switch (weaponstatus[ASHTS_UNDERBARREL]) {
			case 1:
				weaponstatus[ASHTS_FLAGS] |= ASHTF_GZCHAMBER;
				break;
			case 2:
				weaponstatus[ASHTS_FLAGS] |= ASHTF_GZCHAMBER;
				weaponstatus[ASHTS_ZMAG] = 51;
				break;
			default:
				break;
		}
	}
}

enum RPRstatus {
	ASHTF_JUSTUNLOAD=1,
	ASHTF_GLMODE=2,
	ASHTF_GZCHAMBER=4,
	ASHTF_CHAMBERBROKEN=8,
	ASHTF_DIRTYMAG=16,
	ASHTF_STILLPRESSINGRELOAD=32,
	ASHTF_LOADINGDIRTY=64,

	ASHTS_FLAGS=0,
	ASHTS_MAG=1, //-1 unmagged
	ASHTS_CHAMBER=2, //0 empty, 1 spent, 2 animate, 3 loaded
	ASHTS_AUTO=3, //0 semi, 1 burst, 2 auto
	ASHTS_CHOKE=4,
	ASHTS_HEAT=5,
	ASHTS_ZMAG=6,
	ASHTS_ZAUTO=7,
	ASHTS_BOXER=8, // 0 drum mag loaded, 1 box mag loaded
	ASHTS_BOXEE=9, // 0 reload same mag type, 1 reload other mag type
	ASHTS_SIGHTS=10,
	ASHTS_UNDERBARREL=11, // 0 none, 1 UBGL, 2 UBZM
};

class ReaperRandom : IdleDummy {
	states {
		spawn:
			TNT1 A 0 nodelay {
				let wep = RIReaper(spawn("RIReaper", pos, ALLOW_REPLACE));

				if (wep) {
					let lll = random(0, 6);

					let magType = !random(0, 2) ? "RIReapM8" : "RIReapD20";

					wep.weaponstatus[ASHTS_BOXER] = magType == "RIReapM8";

					if (lll <= 3) {
						// Summon Standard Reaper w/ Drum Mags
						spawn(magType, pos + (7, 0, 0), ALLOW_REPLACE);
						spawn(magType, pos + (5, 0, 0), ALLOW_REPLACE);
					} else if (lll == 6) {

						// Summon UBZM Reaper w/ Box Mags
						wep.weaponstatus[ASHTS_UNDERBARREL] = 2;
						spawn(magType, pos + (10, 0, 0), ALLOW_REPLACE);
						spawn(magType, pos + (9, 0, 0), ALLOW_REPLACE);
						spawn("HD4mMag", pos + (8, 0, 0), ALLOW_REPLACE);
						spawn("HD4mMag", pos + (6, 0, 0), ALLOW_REPLACE);
					} else {

						// Summon UBGL Reaper w/ Drum Mag
						wep.weaponstatus[ASHTS_UNDERBARREL] = 1;
						spawn(magType, pos+(10, 0, 0), ALLOW_REPLACE);
						spawn("HDRocketAmmo", pos + (8, 0, 0), ALLOW_REPLACE);
						spawn("HDRocketAmmo", pos + (5, 0, 0), ALLOW_REPLACE);
					}

					wep.InitializeWepStats(false);
				}
			}
			stop;
	}
}